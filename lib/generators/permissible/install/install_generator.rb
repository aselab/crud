require 'rails/generators/migration'
require 'rails/generators/active_record/migration'

module Permissible
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      extend ActiveRecord::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)
      desc "Installs acts_as_permissible to your application."
      argument :principal_name, :required => true, :desc => "principal model which has permissions"

      def create_models
        inject_into_class("app/models/#{principal_name.underscore}.rb",
          principal_name.camelize.constantize) do
          "  has_many :permissions, :dependent => :destroy\n"
        end

        template 'permission.rb.erb', 'app/models/permission.rb'
      end

      def create_migrations
        migration_template "migration.rb.erb", "db/migrate/create_permissions.rb"
      end
    end
  end
end
