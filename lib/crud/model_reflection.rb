module Crud
  class ModelReflection
    extend Memoist

    private_class_method :new
    attr_reader :model

    def self.[](model)
      @cache ||= {}
      model = model.is_a?(Class) ? model : model.class
      @cache[model] ||= new(model)
    end

    def initialize(model)
      @model = model
    end

    def activerecord?
      return false unless defined?(ActiveRecord::Base)
      !!(model <= ActiveRecord::Base)
    end

    def mongoid?
      return false unless defined?(Mongoid::Document)
      model.include?(Mongoid::Document)
    end

    def column_metadata(name)
      if association_key?(name)
        ref = association_reflection(name)
        name = ref.foreign_key if ref.macro == :belongs_to
        return {name: name.to_sym, type: ref.macro, class: ref.klass}
      end
      if enum_values_for(name)
        return {name: name.to_sym, type: :enum}
      end

      if activerecord?
        meta = model.columns_hash[name.to_s]
        meta && {name: meta.name.to_sym, type: meta.type}
      elsif mongoid?
        name = name.to_s
        meta = model.fields[name]
        type = meta.try(:type)
        type = if type == BSON::ObjectId || name == "id" || name.ends_with?("_id")
          :id
        elsif type == Mongoid::Boolean
          :boolean
        else
          type.is_a?(Class) ? type.name.downcase.to_sym : type
        end
        type && {name: name.to_sym, type: type}
      end
    end

    def column_type(name)
      meta = column_metadata(name) || {}
      meta[:type]
    end

    def column_key?(key)
      !!column_metadata(key)
    end

    def association_reflection(key)
      model.reflect_on_association(key.to_sym)
    end

    def association_key?(key)
      return false unless ref = association_reflection(key)
      mongoid? ? !ref.relation.embedded? : true
    end

    def association_class(key)
      association_reflection(key).try(:klass)
    end

    def enum_values_for(column)
      enum = model.try(:enumerized_attributes).try(:[], column)
      enum && Hash[enum.options]
    end

    def none_condition
      if activerecord?
        "0 = 1"
      elsif mongoid?
        { id: 0 }
      end
    end

    def sanitize_sql(cond)
      return cond unless cond && activerecord?
      result = case cond
      when Array
        model.send(:sanitize_sql_for_conditions, cond)
      when Hash
        # https://github.com/rails/rails/blob/d5902c9e7eaba4db4e79c464d623a7d7e6e2d0e3/activerecord/lib/active_record/sanitization.rb#L89-L100
        attrs = model.send(:table_metadata).resolve_column_aliases(cond)
        attrs = model.send(:expand_hash_conditions_for_aggregates, attrs)
        model.predicate_builder.build_from_hash(attrs.stringify_keys).map { |b|
          model.connection.visitor.compile b
        }.join(' AND ')
      else
        cond
      end
      result.respond_to?(:to_sql) ? result.to_sql : result
    end

    def boolean_cast(value)
      value = value.last if value.is_a?(Array)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    memoize :activerecord?, :mongoid?
  end
end
