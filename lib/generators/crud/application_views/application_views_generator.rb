module Crud
  module Generators
    class ApplicationViewsGenerator < Rails::Generators::Base
      def copy_views
        invoke "crud:views", ["crud/application"]
      end
    end
  end
end
