module Crud
  module Serialization
    extend ActiveSupport::Concern
    include Crud::ModelMethods

    def serializer
      Crud::DefaultSerializer
    end

    def serialization_scope
      {}
    end

    def json_metadata
      {}
    end

    def json_options(items, options = nil)
      defaults = {
        scope: serialization_scope,
        root: false
      }
      if items.respond_to?(:to_ary)
        if items.is_a?(Kaminari::PageScopeMethods)
          defaults[:root] = "items"
          defaults[:meta] = json_metadata.merge(
            per_page: items.limit_value,
            total_count: items.total_count,
            total_pages: items.total_pages,
            current_page: items.current_page
          )
        end
        items = items.to_ary
        defaults[:each_serializer] = serializer
      else
        defaults[:serializer] = serializer
      end
      defaults[:json] = items
      options ? defaults.merge(options) : defaults
    end

    def json_errors_options(item)
      { json: json_errors(item), status: :unprocessable_entity }
    end

    private
    def json_errors(item)
      errors = {}
      if self.class.activerecord?(item)
        item.errors.messages.each do |key, messages|
          key = key.to_s.split(".").first.to_sym
          next if errors.has_key?(key)
          if item.association_cache[key]
            e = association_json_errors(item.send(key))
            errors[key] = e || messages
          else
            errors[key] = messages
          end
        end
      elsif self.class.mongoid?(item)
        errors = item.errors.messages.dup
        item.associations.keys.each do |key|
          key = key.to_sym
          next unless errors.has_key?(key)
          e = association_json_errors(item.send(key))
          errors[key] = e if e
        end
      end
      errors
    end

    def association_json_errors(association)
      errors = if association.respond_to?(:to_ary)
        association.each.with_index.each_with_object({}) do |(o, i), h|
          h[i] = json_errors(o) unless o.errors.empty?
        end
      else
        json_errors(association)
      end
      errors.empty? ? nil : errors
    end
  end
end
