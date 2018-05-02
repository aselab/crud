module Crud
  class SearchQuery
    class NotSupportedType < StandardError
    end

    class Operator
      attr_reader :model, :reflection, :meta, :name, :type, :enum_values
      delegate :activerecord?, :mongoid?, to: :reflection

      @@operators = {}
      @@aliases = {}
      @@operators_for_type = {}
      def self.register(alias_name = nil)
        name = self.operator_name.to_s
        @@operators[name] = self
        @@aliases[alias_name.to_s] = name if alias_name
        self.supported_types.each do |type|
          (@@operators_for_type[type] ||= []).push(self)
        end
      end

      def self.operator_name
        @operator_name ||= self.name.demodulize.sub(/Operator$/, "").underscore
      end

      def self.supported_types
        []
      end

      def self.[](name)
        @@operators[canonical_name(name)]
      end

      def self.canonical_name(name)
        @@aliases[name.to_s] || name.to_s
      end

      def self.available_for(type)
        @@operators_for_type[type.try(:to_sym)]
      end

      def self.label
        I18n.t("crud.operator.#{operator_name}")
      end

      def self.args
        instance_method(:condition).arity
      end

      def initialize(model, column)
        @model = model
        @reflection = ModelReflection[model]
        @meta = reflection.column_metadata(column) || {}
        @name = @meta[:name]
        @type = @meta[:type]
        @enum_values = reflection.enum_values_for(column) if @type == :enum
      end

      def validate!
        raise NotSupportedType, meta unless self.class.supported_types.include?(type)
      end

      def cast(value)
        case type
        when :enum
          return value.map {|v| cast(v)} if value.is_a?(Array)
          enum_values[value] || reflection.cast(meta[:original_type], value)
        else
          reflection.cast(type, value)
        end
      end

      def apply(*values)
        #validate!
        values = cast(values)
        reflection.sanitize_sql condition(*values)
      rescue
        reflection.none_condition
      end

      def condition
        raise NotImplementedError
      end
    end

    class DefaultOperator < Operator
      def apply(value)
        case type
        when :string, :text
          ContainsOperator.new(model, name).apply(value)
        when :active_storage
          ContainsOperator.new(ActiveStorage::Blob, :filename).apply(value)
        when :belongs_to, :has_one, :has_many, :has_and_belongs_to_many
          raise if mongoid?
          association = meta[:class]
          ref = ModelReflection[association]
          columns = association.respond_to?(:search_field, true) ?
            association.send(:search_field) :
            [:name, :title].find {|c| ref.column_key?(c)}
          conds = Array(columns).map {|c| self.class.new(association, c).apply(value)}
          conds.empty? ? nil : conds.join(" OR ")
        else
          EqualsOperator.new(model, name).apply(value)
        end
      end
    end

    class EqualsOperator < Operator
      def self.supported_types
        [:belongs_to, :active_storage, :enum, :string, :text, :boolean, :integer, :float, :decimal, :datetime, :date, :time]
      end

      def condition(value)
        if type == :active_storage
          ActiveStorage::Blob.arel_table[:filename].eq(value)
        elsif activerecord?
          model.arel_table[name].eq(value)
        elsif mongoid?
          { name => value }
        end
      end
    end

    class NotEqualsOperator < Operator
      def self.supported_types
        [:belongs_to, :active_storage, :enum, :string, :text, :integer, :float, :decimal, :datetime, :date, :time]
      end

      def condition(value)
        if type == :active_storage
          ActiveStorage::Blob.arel_table[:filename].not_eq(value)
        elsif activerecord?
          model.arel_table[name].not_eq(value)
        elsif mongoid?
          { name.ne => value }
        end
      end
    end

    class ContainsOperator < Operator
      def self.supported_types
        [:has_many, :has_and_belongs_to_many, :active_storage, :string, :text]
      end

      def condition(value)
        case type
        when :active_storage
          ActiveStorage::Blob.arel_table[:filename].matches("%#{value}%")
        when :string, :text
          if activerecord?
            model.arel_table[name].matches("%#{value}%")
          elsif mongoid?
            { name => Regexp.new(Regexp.escape(value)) }
          end
        else
          if activerecord?
            model.arel_table[name].in(value)
          elsif mongoid?
            { name.in => value }
          end
        end
      end
    end

    class NotContainsOperator < Operator
      def self.supported_types
        [:active_storage, :string, :text]
      end

      def condition(value)
        if type == :active_storage
          ActiveStorage::Blob.arel_table[:filename].matches("%#{value}%").not
        elsif activerecord?
          model.arel_table[name].matches("%#{value}%").not
        elsif mongoid?
          { name.not => Regexp.new(Regexp.escape(value)) }
        end
      end
    end

    class AnyOfOperator < Operator
      def condition(*values)
        if activerecord?
          model.arel_table[name].in(values)
        elsif mongoid?
          { name.in => values }
        end
      end
    end

    class GreaterOrEqualOperator < Operator
      def self.supported_types
        [:integer, :float, :decimal, :datetime, :date, :time]
      end

      def condition(value)
        if activerecord?
          model.arel_table[name].gteq(value)
        elsif mongoid?
          { name.gte => value }
        end
      end
    end

    class LessOrEqualOperator < Operator
      def self.supported_types
        [:integer, :float, :decimal, :datetime, :date, :time]
      end

      def condition(value)
        if activerecord?
          model.arel_table[name].lteq(value)
        elsif mongoid?
          { name.lte => value }
        end
      end
    end

    class BetweenOperator < Operator
      def self.supported_types
        [:integer, :float, :decimal, :datetime, :date, :time]
      end

      def condition(s, e)
        if activerecord?
          model.arel_table[name].between(s..e)
        elsif mongoid?
          { name => s..e }
        end
      end
    end

    class AnyOperator < NotEqualsOperator
      def self.supported_types
        []
      end

      def condition
        super nil
      end
    end

    class NoneOperator < EqualsOperator
      def self.supported_types
        []
      end

      def condition
        super nil
      end
    end

    EqualsOperator.register("=")
    NotEqualsOperator.register("!=")
    ContainsOperator.register("~")
    NotContainsOperator.register("!~")
    AnyOfOperator.register("in")
    GreaterOrEqualOperator.register(">=")
    LessOrEqualOperator.register("<=")
    BetweenOperator.register("<>")
    AnyOperator.register("*")
    NoneOperator.register("!*")
  end
end
