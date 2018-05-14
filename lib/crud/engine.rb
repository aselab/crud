module Crud
  class Engine < ::Rails::Engine
    config.autoload_paths += Dir["#{config.root}/app/**/concerns/"]

    initializer "acts_as_permissible" do
      ActiveSupport.on_load(:active_record) do
        ::ActiveRecord::Base.send(:include, ::Acts::Permissible::ActiveRecordExtension)
      end
    end
  end
end
