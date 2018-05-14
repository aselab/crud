module Crud
  module Inputs
    class Select2Input < SimpleForm::Inputs::CollectionSelectInput
      def input(wrapper_options)
        if ajax?
          if options[:selected_item].present?
            options[:collection] = [options[:selected_item]]
          else
            options[:collection] = init_data(value)
          end
        end

        js = template.javascript_tag(<<-SCRIPT
          $(function() {
            $("##{input_id}").val(#{value.inspect}).crudSelect2(#{select2_options(input_options).to_json});
            #{onChangeHintScript}
          });
          SCRIPT
        )

        super(wrapper_options.merge(multiple: multiple?)) + js
      end

      def value
        @value ||= input_options[:selected] ||
          (object.respond_to?(attribute_name) && object.send(attribute_name)) || []
      end

      def multiple?
        if @multiple.nil?
          @multiple = options[:multiple]
          @submit_event = @multiple if @multiple.is_a?(String)
          if @multiple.nil?
            @multiple = reflection ? reflection.macro == :has_many || reflection.macro == :has_and_belongs_to_many : false
          end
        end
        @multiple
      end

      def onChangeHintScript
        return @onChangeHintScript if @onChangeHintScript
        if options[:onChangeHint]
          @onChangeHintScript = <<-SCRIPT
            var target = $("##{input_id}");
            var hint = target.siblings("small.text-muted");
            var hintBody, hintHtml = "";
          SCRIPT
          options[:collection].map do |resource|
            @onChangeHintScript << <<-SCRIPT
              hintBody = #{options[:onChangeHint].gsub(/\$data\.(\w+)/) {|property| resource.send($1).inspect}};
              hintHtml += $("<span/>").html(hintBody).attr({"data-id": #{resource.id}, "class": "chnage_hint_effect"}).get(0).outerHTML;
            SCRIPT
          end
          @onChangeHintScript << <<-SCRIPT
            if (hint.length) {
              hint.html(hintHtml);
            } else {
              var newHint = $("<small/>").attr("class", "form-text text-muted").html(hintHtml);
              newHint.appendTo(target.parent());
            }
          SCRIPT
          @onChangeHintScript
        end
      end

      def submit_event
        @submit_event ||= "submit"
      end

      def url
        @url ||= input_options.delete(:url) || template.polymorphic_path(model)
      end

      def ajax?
        @ajax ||= input_options[:url].present? || input_options[:ajax]
      end

      def init_data(ids)
        return [] if ids.blank?
        model ? model.where(id: ids) : ids
      end

      def model
        @model ||= input_options.delete(:model) || reflection.try(:klass)
      end

      def select2_options(options)
        name = reflection.try(:name) || attribute_name
        options[:placeholder] ||= I18n.t("simple_form.select2.placeholder", name: object.class.human_attribute_name(name))
        options[:language] = I18n.locale
        options.except(:as, :collection, :model).transform_keys {|key| key.to_s.camelize(:lower)}
      end
    end
  end
end
