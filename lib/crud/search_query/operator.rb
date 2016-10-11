module Crud
  class SearchQuery
    class NotSupportedType < StandardError
    end

    class Operator
      attr_reader :model, :reflection, :name, :type, :enum_values
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
        raise NotImplementedError
      end

      def self.[](name)
        @@operators[canonical_name(name)]
      end

      def self.canonical_name(name)
        @@aliases[name.to_s] || name.to_s
      end

      def self.available_for(type)
        @@operators_for_type[type.to_sym]
      end

      def self.label
        I18n.t("crud.operator.#{operator_name}")
      end

      def self.args
        instance_method(:condition).arity
      end

      def initialize(model, column)
        reflection = ModelReflection[model]
        if reflection.activerecord? && association = reflection.association_class(column)
          model = association
          reflection = ModelReflection[association]
          column = association.respond_to?(:search_field, true) ?
            association.send(:search_field) :
            [:name, :title].find {|c| reflection.column_key?(c)}
        end

        @model = model
        @reflection = reflection
        meta = reflection.column_metadata(column) || {}
        @name = meta[:name]
        @type = meta[:type]
        raise NotSupportedType, meta unless self.class.supported_types.include?(@type)
        @enum_values = reflection.enum_values_for(column) if @type == :enum
      end

      def apply(*values)
        values = values.map do |value|
          case type
          when :enum
            enum_values[value] || value
          when :boolean
            !!value
          when :integer
            Integer(value)
          when :float
            Float(value)
          else
            value
          end
        end
        condition(*values)
      rescue
        reflection.none_condition
      end

      def condition
        raise NotImplementedError
      end
    end

    class EqualsOperator < Operator
      def self.supported_types
        [:enum, :string, :text, :boolean, :integer, :float, :datetime, :date, :time]
      end

      def condition(value)
        if activerecord?
          model.arel_table[name].eq(value)
        elsif mongoid?
          { name => value }
        end
      end
    end

    class NotEqualsOperator < Operator
      def self.supported_types
        [:enum, :string, :text, :boolean, :integer, :float, :datetime, :date, :time]
      end

      def condition(value)
        if activerecord?
          model.arel_table[name].not_eq(value)
        elsif mongoid?
          { name.ne => value }
        end
      end
    end

    class ContainsOperator < Operator
      def self.supported_types
        [:string, :text]
      end

      def condition(value)
        if activerecord?
          model.arel_table[name].matches("%#{value}%")
        elsif mongoid?
          { name => Regexp.new(Regexp.escape(value)) }
        end
      end
    end

    class NotContainsOperator < ContainsOperator
      def condition(value)
        if activerecord?
          super.not
        elsif
          { name.not => Regexp.new(Regexp.escape(value)) }
        end
      end
    end

    class GreaterOrEqualOperator < Operator
      def self.supported_types
        [:integer, :float, :datetime, :date, :time]
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
        [:integer, :float, :datetime, :date, :time]
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
        [:integer, :float, :datetime, :date, :time]
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
      def condition
        super nil
      end
    end

    class NoneOperator < EqualsOperator
      def condition
        super nil
      end
    end

    EqualsOperator.register("=")
    NotEqualsOperator.register("!=")
    ContainsOperator.register("~")
    NotContainsOperator.register("!~")
    GreaterOrEqualOperator.register(">=")
    LessOrEqualOperator.register("<=")
    BetweenOperator.register("<>")
    AnyOperator.register("*")
    NoneOperator.register("!*")
  end
end
