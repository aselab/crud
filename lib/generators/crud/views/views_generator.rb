module Crud
  module Generators
    module ViewPathTemplates #:nodoc:
      extend ActiveSupport::Concern

      included do
        argument :controller_name, :required => true
        public_task :copy_views
      end
    end

    class ApplicationViewsGenerator < Rails::Generators::Base #:nodoc:
      include ViewPathTemplates
      source_root File.expand_path("../../../../../app/views/crud", __FILE__)
      desc "Copies Crud views to your application."

      def copy_views
        directory "application/", "app/views/#{controller_name}/"
      end
    end

    class ViewsGenerator < Rails::Generators::Base
      desc "Copies Crud views to your application."
      argument :controller_name, :required => true, :desc => "The controller name to copy views to"
      invoke ApplicationViewsGenerator
    end
  end
end
