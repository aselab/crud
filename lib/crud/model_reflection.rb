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
      return {name: name, type: :association} if association_key?(name)

      meta = if activerecord?
        model.columns_hash[name.to_s]
      elsif mongoid?
        model.fields[name.to_s]
      end
      type = enum_values_for(name) ? :enum : meta.try(:type) 
      type = type.is_a?(Class) ? type.name.downcase.to_sym : type
      meta && {name: meta.name.to_sym, type: type}
    end

    def column_type(name)
      meta = column_metadata(name) || {}
      meta[:type]
    end

    def column_key?(key)
      !!column_metadata(key)
    end

    def association_key?(key)
      return false unless ref = model.reflect_on_association(key.to_sym)
      mongoid? ? !ref.relation.embedded? : true
    end

    def association_class(key)
      model.reflect_on_association(key.to_sym).try(:klass)
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
      return cond unless activerecord?
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

    memoize :activerecord?, :mongoid?
  end
end
