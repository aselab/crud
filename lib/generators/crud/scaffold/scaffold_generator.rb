module Crud
  module Generators
    class ScaffoldGenerator < Rails::Generators::ModelGenerator
      include Rails::Generators::ResourceHelpers
      class_option :copy_views, desc: "copy views", type: :boolean

      def invoke_controller
        keys = attributes.map {|a| a.reference? ? a.name + "_id" : a.name }
        invoke "crud:controller", [controller_name, *keys], options.slice(:copy_views)
      end
    end
  end
end
