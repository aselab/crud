# coding: utf-8
class Select2Input < SimpleForm::Inputs::CollectionInput
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::JavaScriptHelper
  include Rails.application.routes.url_helpers

  def input
    multiple_js = <<-SCRIPT
      select.closest("form").submit(function() {
        var form = $(this);
        $.each(select.select2("val"), function() {
          if (this != "[]") form.append($("<input/>").attr({"type": "hidden", "name": "#{object_name}[#{attribute_name}][]"}).val(this));
        });
        select.remove();
      });
    SCRIPT

    js = javascript_tag(<<-SCRIPT
      $(function() {
        var select = $("##{input_id}");
        select.select2(#{select2_options(input_options)}).select2("val", #{(object.send(attribute_name) || []).inspect});
        #{multiple_js if multiple?}
      });
      SCRIPT
    )

    @builder.hidden_field(attribute_name, input_html_options) + js
  end

  def multiple?
    if @multiple.nil?
      @multiple = options[:multiple]
      if @multiple.nil?
        @multiple = reflection ? reflection.macro == :has_many || reflection.macro == :has_and_belongs_to_many : false
      end
    end
    @multiple
  end

  def url
    @url ||= input_options.delete(:url) || polymorphic_path(reflection.klass)
  end

  def ajax?
    @ajax ||= input_options[:url].present? || input_options[:ajax]
  end

  def input_id
    "select2_#{attribute_name}"
  end

  def select2_options(options)
    label = options.delete(:label) || "name"
    options[:placeholder] ||= "#{I18n.t("simple_form.select2.placeholder", :name => object.class.human_attribute_name(attribute_name))}"

    ids = object.send(attribute_name)
    append_options = []
    if ajax?
      init_data = reflection.klass.where(:id => ids).select([:id, label]).map {|m| {id: m.id, text: m.send(label)}}
      init_data = init_data.first unless multiple?
      append_options << <<-STRING
        ,initSelection: function(element, callback) { callback(#{init_data.to_json}); }
      STRING
    else
      load_data = options[:collection].map {|m| {id: m.id, text: m.send(label)}} unless ajax?
      append_options << <<-STRING
        ,data: #{load_data.to_json}
      STRING
    end

    append_options << <<-STRING if ajax?
      ,ajax: {
        url: "#{url}",
        dataType: "json",
        quietMillis: 200,
        cache: true,
        data: function(term, page) {
          return {term: term, page: page};
        },
        results: function(d, page) {
          $(d.data).each(function() { this.text = this.#{label}; });
          return {results: d.data, more: page < d.current_page};
        }
      }
    STRING
    {:multiple => multiple?, :allowClear => true, :width => "element"}.merge(options).to_json.sub(/}$/, append_options.join("") + "}")
  end

  def input_html_options
    options = super
    options['id'] ||= input_id
    options
  end
end
