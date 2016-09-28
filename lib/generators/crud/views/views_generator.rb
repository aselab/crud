module Crud
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../../../app/views/crud", __FILE__)
      desc "Copies Crud views to your application."
      argument :name, required: true, desc: "The controller name to copy views to"

      def copy_views
        directory "application/", "app/views/#{name}/"
      end
    end
  end
end
