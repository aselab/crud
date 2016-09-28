module Crud
  module Generators
    class ControllerGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("../templates", __FILE__)
      class_option :skip_routes, type: :boolean, desc: "Don't add routes to config/routes.rb."
      class_option :copy_views, desc: "copy views", type: :boolean

      check_class_collision suffix: "Controller"

      def create_controller_files
        template "controller.rb", File.join("app/controllers", class_path, "#{file_name}_controller.rb")
      end

      def create_helper_files
        template "helper.rb", File.join("app/helpers", class_path, "#{file_name}_helper.rb")
      end

      def add_routes
        invoke "resource_route"
      end

      #def copy_views
      #  invoke "crud:views", [controller_name] if options[:copy_views]
      #end
    end
  end
end
