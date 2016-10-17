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
rescue LoadError
end

module Crud
  class NotAuthorizedError < StandardError
  end
end

require 'acts_as_permissible'
require 'crud/engine'
require 'crud/model_reflection'
require 'crud/search_query'
