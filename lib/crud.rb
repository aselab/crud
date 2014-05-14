require 'jquery-rails'
require 'bootstrap-sass'
require 'font-awesome-sass-rails'
require 'kaminari'
require 'simple_form'
require 'select2-rails'
require 'crud/engine'
require 'acts_as_permissible'

module Crud
  class NotAuthorizedError < StandardError
  end
end
