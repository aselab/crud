module Crud
  class DefaultSerializer < ActiveModel::Serializer
    def attributes
      scope[:columns].each_with_object({}) do |name, h|
        h[name] = object.send(name)
      end
    end
  end
end
