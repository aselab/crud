# coding: utf-8
class Select2Input < SimpleForm::Inputs::CollectionInput
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::JavaScriptHelper
  include Rails.application.routes.url_helpers

  def input(wrapper_options)
    id = input_id
    options[:collection] = [] if ajax?
    def multiple_js
      <<-SCRIPT
      select.closest('form').on("#{submit_event}", function () {
        var form = $(this);
        if (!$.contains(this, select[0])) {
          form.off("#{submit_event}", arguments.callee);
          return;
        }
        var input = $("<input/>").attr({type: "hidden", name: "#{object_name}[#{attribute_name}][]"});
        form.append(input);
        $.each(select.select2("val"), function() {
          form.append(input.clone().val(this));
        });
        select.remove();
      });
      SCRIPT
    end

    js = javascript_tag(<<-SCRIPT
      $(function() {
        var select = $("##{id}");
        select.select2(#{select2_options(input_options)}).select2("val", #{(object.send(attribute_name) || []).inspect});
        #{'select.data("select2").container.css("width", "100%");' unless input_options.has_key?(:width)}
        #{multiple_js if multiple?}
      });
      SCRIPT
    )

    @builder.hidden_field(attribute_name, input_html_options) + js
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
    @url ||= input_options.delete(:url) || polymorphic_path(reflection.klass)
  end

  def ajax?
    @ajax ||= input_options[:url].present? || input_options[:ajax]
  end

  def input_id
    input_html_options[:id] ||= "#{object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")}_#{attribute_name}"
  end

  def init_data(label, ids)
    reflection.klass.where(:id => ids).map {|m| {id: m.id, text: m.send(label)}}
  end

  def select2_options(options)
    search_key = options.delete(:search_key) || "term"
    label = options.delete(:label_method) || "name"
    name = reflection.try(:name) || attribute_name
    options[:placeholder] ||= "#{I18n.t("simple_form.select2.placeholder", :name => object.class.human_attribute_name(name))}"

    ids = object.send(attribute_name)
    append_options = []
    if ajax?
      init_data = init_data(label, ids)
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
        quietMillis: 300,
        cache: true,
        data: function(term, page) {
          return {#{search_key}: term, page: page};
        },
        results: function(d, page) {
          $(d.items).each(function() { this.text = this.#{label}; });
          return {results: d.items, more: page < d.meta.total_pages};
        }
      }
    STRING
    {:multiple => multiple?, :allowClear => true}.merge(options).to_json.sub(/}$/, append_options.join("") + "}")
  end
end
