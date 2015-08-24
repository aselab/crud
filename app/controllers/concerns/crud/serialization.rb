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
      errors = item.errors.messages.dup
      if self.class.mongoid?(item)
        item.associations.keys.each do |key|
          key = key.to_sym
          next unless errors.has_key?(key)
          target = item.send(key)
          errors[key] = if target.respond_to?(:to_ary)
            e = target.each.with_index.each_with_object({}) do |(o, i), h|
              h[i] = o.errors.messages unless o.errors.empty?
            end
            e.empty? ? errors[key] : e
          else
            target.errors.empty? ? errors[key] : target.errors.messages
          end
        end
      end
      { json: errors, status: :unprocessable_entity }
    end
  end
end