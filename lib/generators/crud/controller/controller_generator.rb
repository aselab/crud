module Crud
  module Generators
    class ControllerGenerator < Rails::Generators::Base
      source_root File.expand_path("../", __FILE__)
      desc "Copies Crud controller and views to your application."
      argument :controller_name, :required => true, :desc => "The controller name to copy views to"
      class_option :skip_views, :desc => "skip generate views", :type => :boolean, :default => false

      def copy_controller
        template 'templates/controller.rb.erb', "app/controllers/#{controller_name}_controller.rb"
        route "resources :#{controller_name}"
      end

      def copy_views
        invoke "crud:views", [controller_name] unless options[:skip_views]
      end
    end
  end
end
