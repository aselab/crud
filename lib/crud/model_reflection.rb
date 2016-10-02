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
      if activerecord?
        model.columns_hash[name.to_s]
      elsif mongoid?
        model.fields[name.to_s]
      end
    end

    def column_type(name)
      type = column_metadata(name).try(:type)
      type.is_a?(Class) ? type.name.downcase.to_sym : type
    end

    def column_key?(key)
      !!column_metadata(key)
    end

    def association_key?(key)
      !!model.reflect_on_association(key.to_sym)
    end

    def association_class(key)
      model.reflect_on_association(key.to_sym).try(:klass)
    end

    memoize :activerecord?, :mongoid?
  end
end
