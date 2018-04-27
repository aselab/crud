require 'crud_api'
require 'simple_form'
require 'webpacker'

# Mongoid 7.0 でmacroメソッドが削除されている対策
if defined? Mongoid && Mongoid::VERSION > "7.0.0"
  module Mongoid::Association
    REVERSE_MACRO_MAPPING = MACRO_MAPPING.invert

    module Relatable
      def macro
        REVERSE_MACRO_MAPPING[self.class]
      end
    end
  end
end
