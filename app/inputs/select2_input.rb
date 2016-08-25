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
        var select = $("##{input_id}");
        select.select2(#{select2_options(input_options)});
        #{'select.data("select2").$container.css("width", "100%");' unless input_options.has_key?(:width)}
        select.val(#{value.inspect}).trigger("change");
      });
      SCRIPT
    )

    super(wrapper_options.merge(multiple: multiple?)) + js
  end

  def value
    @value ||= input_options[:value] || input_options[:input_html].try("[]", :value) ||
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
    @url ||= input_options.delete(:url) || reflection && polymorphic_path(reflection.klass)
  end

  def ajax?
    @ajax ||= input_options[:url].present? || input_options[:ajax]
  end

  def input_id
    input_html_options[:id] ||= "#{object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")}_#{attribute_name}"
  end

  def init_data(ids)
    reflection.try(:klass).try(:where, :id => ids)
  end

  def select2_options(options)
    search_key = options.delete(:search_key) || "term"
    label = options[:label_method] || "name"
    name = reflection.try(:name) || attribute_name
    options[:placeholder] ||= "#{I18n.t("simple_form.select2.placeholder", :name => object.class.human_attribute_name(name))}"

    append_options = []
    append_options << <<-STRING if ajax?
      ,ajax: {
        url: "#{url}",
        dataType: "json",
        delay: 300,
        cache: true,
        data: function(params) {
          return {#{search_key}: params.term, page: params.page};
        },
        processResults: function(d, params) {
          $(d.items).each(function() { this.text = this.#{label}; });
          var currentPage = params.page || 1;
          return {results: d.items, pagination: {more: currentPage < d.meta.total_pages}};
        },
        cache: true
      }
    STRING
    {:multiple => multiple?, :allowClear => true}.merge(options).to_json.sub(/}$/, append_options.join("") + "}")
  end
end
