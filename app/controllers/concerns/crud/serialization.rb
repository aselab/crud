module Crud
  module Serialization
    extend ActiveSupport::Concern

    def serializer
      Crud::DefaultSerializer
    end

    def serialization_scope
      {}
    end

    def json_metadata
      {}
    end

    def render_json_options(items, options = nil)
      defaults = {
        json: items,
        scope: serialization_scope,
        root: false
      }
      if items.is_a?(Kaminari::PageScopeMethods)
        defaults[:each_serializer] = serializer
        defaults[:root] = "items"
        defaults[:meta] = json_metadata.merge(
          per_page: items.limit_value,
          total_count: items.total_count,
          total_pages: items.total_pages,
          current_page: items.current_page
        )
      elsif items.respond_to?(:to_ary)
        defaults[:each_serializer] = serializer
      else
        defaults[:serializer] = serializer
      end
      options ? defaults.merge(options) : defaults
    end
  end
end
