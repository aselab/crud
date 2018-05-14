module Crud
  module Inputs
    extend ActiveSupport::Autoload

    autoload :BootstrapFilestyleInput
    autoload :FlatpickrInput
    autoload :DatetimePickerInput
    autoload :DatePickerInput
    autoload :TimePickerInput
    autoload :ModalPickerInput
    autoload :Select2Input

    module InputId
      def input_id
        input_html_options[:id] ||= "#{object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")}_#{attribute_name}"
      end
    end

    SimpleForm::Inputs::Base.send(:include, InputId)
  end
end
