module Crud
  class Engine < ::Rails::Engine
    config.autoload_paths += Dir["#{config.root}/app/**/concerns/"]
  end
end
