require 'rails/generators'

module Permissible
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)
      desc "Installs acts_as_permissible to your application."
      class_option :principal, type: :string, default: "User"
      class_option :permission, type: :string, default: "Permission"
      class_option :permissible_name, type: :string, default: "permissible"
      class_option :orm, type: :string, default: "active_record"

      def create_models
        case orm
        when :active_record
          inject_into_class("app/models/#{principal_name}.rb", options[:principal].constantize) do
            "  has_many :#{permission_name.pluralize}, dependent: :destroy\n"
          end

          template "permission.rb.erb", "app/models/#{permission_name}.rb"
        when :mongoid
          template "mongoid_permission.rb.erb", "app/models/#{permission_name}.rb"
        end
      end

      def create_migrations
        if orm == :active_record
          require 'rails/generators/active_record'
          self.class.send(:include, ActiveRecord::Generators::Migration)
          migration_template "migration.rb.erb", "db/migrate/create_#{permission_name.pluralize}.rb"
        end
      end

      private
      def orm
        options[:orm].to_sym
      end

      def principal_name
        options[:principal].underscore
      end

      def permission_name
        options[:permission].underscore
      end

      def permissible_name
        options[:permissible_name]
      end
    end
  end
end
