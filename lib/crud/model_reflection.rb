module Crud
  class ModelReflection
    extend Memoist
    @@type_hash = {}

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
        return if ref.options[:polymorphic]
        name = ref.foreign_key if ref.macro == :belongs_to
        return {name: name.to_sym, type: ref.macro, class: ref.klass}
      elsif active_storage_key?(name)
        return {name: name.to_sym, type: :active_storage}
      end

      metadata = if activerecord?
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
        elsif type == BigDecimal
          :decimal
        else
          type.is_a?(Class) ? type.name.downcase.to_sym : type
        end
        type && {name: name.to_sym, type: type}
      end

      if metadata && enum_values_for(name)
        metadata[:original_type] = metadata[:type]
        metadata[:type] = :enum
      end

      metadata
    end

    def column_type(name)
      meta = column_metadata(name) || {}
      meta[:type]
    end

    def column_key?(key)
      !!column_metadata(key)
    end

    def nested_attributes
      @nested_attributes ||= if activerecord?
        model.nested_attributes_options.keys
      elsif mongoid?
        model.nested_attributes.keys.map {|key| key.sub(/_attributes\z/, "").to_sym}
      else
        []
      end
    end

    def association_reflections
      @association_reflections ||= if activerecord?
        model.reflections.values
      elsif mongoid?
        model.relations.values
      else
        []
      end
    end

    def association_reflection(key)
      model.reflect_on_association(key.to_sym) if activerecord? || mongoid?
    end

    def association_key?(key)
      return false unless ref = association_reflection(key)
      mongoid? ? !ref.relation.embedded? : true
    end

    def active_storage_key?(key)
      activerecord? && model.new.try(key).is_a?(ActiveStorage::Attached)
    end

    def searchable?(column)
      return false unless meta = column_metadata(column)
      return true if [:enum, :string, :text, :integer, :float, :decimal].include?(meta[:type])
      activerecord? && (association_key?(column) || active_storage_key?(column))
    end

    def sortable?(column)
      return true if column_key?(column)
      activerecord? && (association_key?(column) || active_storage_key?(column))
    end

    def association_class(key)
      association_reflection(key).try(:klass)
    end

    def enum_values_for(column)
      enum = model.try(:enumerized_attributes).try(:[], column)
      enum && enum.values.flat_map {|v| [[v.text, v.value], [v.to_s, v.value]] }.to_h
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
      result = model.send(:sanitize_sql_for_conditions, cond)
      result.respond_to?(:to_sql) ? result.to_sql : result
    end

    def cast(type, value)
      return value.map {|v| cast(type, v)} if value.is_a?(Array)

      @@type_hash[type] = ActiveModel::Type.lookup(type) rescue nil unless @@type_hash.key?(type)
      t = @@type_hash[type]
      return value unless t
      raise "invalid number: #{value.inspect}" if t.is_a?(ActiveModel::Type::Helpers::Numeric) && t.send(:non_numeric_string?, value)
      t.cast(value)
    end

    memoize :activerecord?, :mongoid?, :column_metadata
  end
end
