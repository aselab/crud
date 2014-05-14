require 'rails/generators'
require 'rails/generators/active_record'

module Permissible
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)
      desc "Installs acts_as_permissible to your application."

      def create_models
        inject_into_class("app/models/user.rb", User) do
          "  has_many :permissions, dependent: :destroy\n"
        end

        template 'permission.rb.erb', 'app/models/permission.rb'
      end

      def create_migrations
        migration_template "migration.rb.erb", "db/migrate/create_permissions.rb"
      end
    end
  end
end
