module Crud
  module Generators
    class ControllerGenerator < Rails::Generators::Base
      source_root File.expand_path("../", __FILE__)
      desc "Generates CRUD controller and copies views to your application."
      argument :controller_name, :required => true, :desc => "The controller name to copy views to"
      class_option :copy_views, :desc => "copy views", :type => :boolean, :default => false

      def copy_controller
        template 'templates/controller.rb.erb', "app/controllers/#{controller_name}_controller.rb"
        template 'templates/helper.rb.erb', "app/helpers/#{controller_name}_helper.rb"
        route "resources :#{controller_name}"
      end

      def copy_views
        invoke "crud:views", [controller_name] if options[:copy_views]
      end
    end
  end
end
