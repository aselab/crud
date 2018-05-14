require 'csv'
require 'kaminari'
require 'active_model_serializers'
require 'memoist'
require 'acts_as_permissible'

Mime::Type.register_alias "text/javascript", :form

module Crud
  class NotAuthorizedError < StandardError
  end
end

require 'crud/mongoid'
require 'crud/config'
require 'crud/engine'
require 'crud/model_reflection'
require 'crud/search_query'
