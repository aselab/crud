module Crud
  module Inputs
    class FlatpickrInput < SimpleForm::Inputs::StringInput
      def input(wrapper_options = nil)
        script + super
      end

      def script
        template.javascript_tag(<<-EOT)
          $(function() {
            $("##{input_id}").flatpickr(#{picker_options.to_json});
          });
        EOT
      end

      def picker_options
        default_options.merge(input_options[:flatpickr] || {})
      end

      def default_options
        { locale: I18n.locale }
      end
    end
  end
end
