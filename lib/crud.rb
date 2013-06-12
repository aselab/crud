require "crud/engine"
require "acts_as_permissible"

module Crud
  class Engine < ::Rails::Engine
    require 'select2-rails'
  end
end
