# coding: utf-8
class Select2Input < SimpleForm::Inputs::CollectionSelectInput
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::JavaScriptHelper
  include Rails.application.routes.url_helpers

  def input(wrapper_options)
    if ajax? && options[:collection].blank? && object.respond_to?(attribute_name)
      options[:collection] = init_data(value)
    end

    js = javascript_tag(<<-SCRIPT
      $(function() {
        $("##{input_id}").val(#{value.inspect}).crudSelect2(#{select2_options(input_options).to_json});
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

  def submit_event
    @submit_event ||= "submit"
  end

  def url
    @url ||= input_options.delete(:url) || polymorphic_path(model)
  end

  def model
  end

  def ajax?
    @ajax ||= input_options[:url].present? || input_options[:ajax]
  end

  def input_id
    input_html_options[:id] ||= "#{object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")}_#{attribute_name}"
  end

  def init_data(ids)
    model.where(id: ids)
  end

  def model
    @model ||= input_options.delete(:model) || reflection.klass
  end

  def select2_options(options)
    name = reflection.try(:name) || attribute_name
    options[:placeholder] ||= I18n.t("simple_form.select2.placeholder", name: object.class.human_attribute_name(name))
    options.except(:as, :collection).transform_keys {|key| key.to_s.camelize(:lower)}
  end
end
