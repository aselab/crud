require 'jquery-rails'
require 'bootstrap-sass'
require 'font-awesome-sass-rails'
require 'kaminari'
require 'simple_form'
require 'select2-rails'
require 'crud/engine'
require 'acts_as_permissible'
require 'active_model_serializers'

begin
  require 'mongoid'
  module BSON
    class ObjectId   
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
