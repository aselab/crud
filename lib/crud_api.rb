require 'csv'
require 'kaminari'
require 'active_model_serializers'
require 'memoist'

Mime::Type.register_alias "text/javascript", :form

begin
  require 'mongoid'
  module BSON
    class ObjectId   
      def inspect
        to_s.inspect
      end

      def as_json(options = nil)
        to_s
      end
    end
  end

  # Mongoid 7.0 でmacroメソッドが削除されている対策
  if Mongoid::VERSION >= "7.0.0"
    module Mongoid::Association
      REVERSE_MACRO_MAPPING = MACRO_MAPPING.invert

      module Relatable
        def macro
          REVERSE_MACRO_MAPPING[self.class]
        end
      end
    end
  end
rescue LoadError
end

module Crud
  class NotAuthorizedError < StandardError
  end
end

require 'acts_as_permissible'
require 'crud/engine'
require 'crud/railtie'
require 'crud/model_reflection'
require 'crud/search_query'
