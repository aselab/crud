begin
  require 'mongoid'
  ::Mongoid::Document.send(:include, ::Acts::Permissible::MongoidExtension) if defined? ::Mongoid

  module BSON
    class ObjectId   
      def inspect
        to_s.inspect
      end

      def as_json(options = nil)
        to_s
      end
    end
  end

  # Mongoid 7.0 でmacroメソッドが削除されている対策
  if Mongoid::VERSION >= "7.0.0"
    module Mongoid::Association
      REVERSE_MACRO_MAPPING = MACRO_MAPPING.invert

      module Relatable
        def macro
          REVERSE_MACRO_MAPPING[self.class]
        end
      end
    end
  end
rescue LoadError
end

