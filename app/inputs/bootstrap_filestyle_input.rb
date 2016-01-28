# coding: utf-8
class BootstrapFilestyleInput < SimpleForm::Inputs::FileInput
  include ActionView::Helpers::JavaScriptHelper

  def filestyle_options
    filestyle_options = options[:filestyle_options] || {}
    filestyle_options[:buttonText] ||= I18n.t("simple_form.file_button", name: label_text)
    filestyle_options[:buttonName] ||= "btn-default"
    filestyle_options
  end

  def input_id
    input_html_options[:id] ||= "#{object.model_name.param_key}_#{attribute_name}"
  end

  def script
    javascript_tag <<-SCRIPT
      $(function() {
        $("##{input_id}").filestyle(#{filestyle_options.to_json});
      });
    SCRIPT
  end

  def input(wrapper_options = nil)
    script + super
  end
end
