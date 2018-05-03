module Crud
  class Railtie < ::Rails::Railtie #:nodoc:
    initializer "acts_as_permissible" do
      ActiveSupport.on_load(:active_record) do
        ::ActiveRecord::Base.send(:include, ::Acts::Permissible::ActiveRecordExtension)
      end

      begin
        require 'mongoid'
        ::Mongoid::Document.send(:include, ::Acts::Permissible::MongoidExtension) if defined? ::Mongoid
      rescue LoadError
      end
    end
  end
end
