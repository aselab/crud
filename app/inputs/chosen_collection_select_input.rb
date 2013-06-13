# coding: utf-8
class ChosenCollectionSelectInput < SimpleForm::Inputs::CollectionSelectInput
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::JavaScriptHelper

  def input
    js = javascript_tag(<<-SCRIPT
      $(document).ready(function() {
        $("##{input_id}").chosen();
      });
      SCRIPT
    )

    super + js
  end

  def input_id
    "chosen_#{attribute_name}"
  end

  def input_html_options
    options = super
    options['id'] ||= input_id
    options['multiple'] ||= true
    options['style'] ||= "width: 400px;"
    options['data-placeholder'] ||= "#{object.class.human_attribute_name(attribute_name)}を選択してください。"
    options
  end
end
