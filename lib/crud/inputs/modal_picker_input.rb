module Crud
  module Inputs
    class ModalPickerInput < SimpleForm::Inputs::Base
      def input(wrapper_options)
        js = template.javascript_tag(<<-SCRIPT
          $(function() {
            $("##{input_id}").modalPicker(#{picker_options(input_options).to_json});
          });
          SCRIPT
        )

        @builder.hidden_field(attribute_name, input_html_options) + js
      end

      def multiple?
        return @multiple if @multiple
        @multiple = options[:multiple]
        @submit_event = @multiple if @multiple.is_a?(String)
        if @multiple.nil?
          @multiple = reflection ? reflection.macro == :has_many || reflection.macro == :has_and_belongs_to_many : false
        end
        input_html_options[:multiple] = @multiple
      end

      def model
        @model ||= input_options.delete(:model) || reflection.try(:klass)
      end

      def value
        @value ||= input_options[:selected] || input_options.dig(:input_html, :value) ||
          (object.respond_to?(attribute_name) && object.send(attribute_name)) || []
      end

      def placeholder
        options[:placeholder] ||=
          I18n.t("simple_form.select2.placeholder", name: options[:label] || object.class.human_attribute_name(reflection.try(:name) || attribute_name))
      end

      def init_data(ids)
        return ids unless model
        return [] if ids.blank?
        method = Crud::ModelReflection[model].mongoid? ? :in : :where
        model.send(method, id: ids).map do |v|
          data = pickers_serializer.new(v, scope: pickers_serialization_scope).as_json
          data[:label] ||= to_label(v)
          data
        end
      end

      def pickers_controller_instance
        return @pickers_controller if @pickers_controller
        relative_path = Rails.application.config.relative_url_root || ""
        url = options[:url].gsub(relative_path, "")
        controller_name = "#{Rails.application.routes.recognize_path(url)[:controller].camelize}Controller"
        @pickers_controller = controller_name.constantize.new.tap do |controller|
          def controller.params
            {}
          end
        end
      end

      def pickers_serializer
        pickers_controller_instance.send(:serializer)
      end

      def pickers_serialization_scope
        columns = pickers_controller_instance.send(:columns_for_json)
        template.serialization_scope.merge(columns: columns)
      end

      def label_method
        options[:label_method] || :label
      end

      def value_method
        options[:value_method] || :id
      end

      def to_label(value, blank = nil)
        return blank if value.blank?
        return value.map {|v| to_label(v, blank)}.join(", ") if value.is_a?(Enumerable)
        return I18n.l(value) if value.is_a?(Time) || value.is_a?(Date)
        return value.send(label_method) if value.respond_to?(label_method)
        return value.text if value.respond_to?(:text)
        return value.name if value.respond_to?(:name)
        value.to_s
      end

      def picker_options(options)
        options[:icon] ||= template.crud_icon_tag(:modal_picker)
        options[:selected_item] ||= init_data(value)
        options.slice(:url, :label_method, :value_method, :icon, :selected_item)
          .transform_keys {|key| key.to_s.camelize(:lower)}
          .merge(multiple: multiple?, placeholder: placeholder, onChangeHint: options[:onChangeHint])
      end
    end
  end
end
