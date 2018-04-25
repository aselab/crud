module Crud
  module ApplicationHelper
    def temp_id(prefix)
      "#{prefix}-#{object_id}"
    end

    def link_to_sort(key, options = nil)
      options ||= {}
      label = options.delete(:label) || model.human_attribute_name(key)
      options[:remote] = @remote unless options.has_key?(:remote)
      if sort_key?(key)
        focus = sort_key == key.to_sym
        current = sort_order
        order = focus && current == :asc ? :desc : :asc
        icon = current == :asc ? "fa-sort-asc" : "fa-sort-desc"
        p = options.delete(:params) || params.to_unsafe_hash
        p = p.merge(sort_key: key.to_s, sort_order: order.to_s)
        link = link_to(label, p, options)
        if focus
          link + content_tag(:i, nil, class: "fa " + icon)
        else
          link
        end
      else
        label
      end
    end

    def link_to_action(action, resource = nil, **options, &block)
      method = find_method("link_to_#{action}_options", params[:controller])
      options = send(method).merge(options) if method
      params = stored_params(action: action, id: resource).merge(options.delete(:params) || {})
      method = find_method("link_to_#{action}", params[:controller])
      return send(method, params) if method

      begin
        if can?(action, resource)
          if action == :destroy
            options[:method] ||= :delete
            options[:data] = { confirm: t("crud.message.are_you_sure") }.merge(options[:data] || {})
            options[:class] ||= "btn btn-danger"
          else
            options[:class] ||= "btn btn-default"
          end
          options[:remote] = @remote unless options.has_key?(:remote)
          options[:remote] = @remote_link unless @remote_link.nil?

          if block
            link_to(params, options, &block)
          else
            label = options.delete(:label)
            label ||= action == :new ?
              t("crud.action_title.new", name: model_name) :
              t("crud.action." + action.to_s)
            link_to(label, params, options)
          end
        end
      rescue ActionController::RoutingError, ActionController::UrlGenerationError
      end
    end

    #
    # カラムのhtml表示出力用メソッド.
    # 以下の優先順で表示する。
    # 1. #{controller_name}_#{column_name}_html という名前のhelperメソッド
    # 2. #{column_name}_html という名前のhelperメソッド
    # 3. #{column_name}_label という名前のmodelメソッド
    #
    def column_html(resource, column, prefix = nil)
      return nil unless resource && column
      value = resource.try(column)
      if method = find_method("#{column}_html", prefix)
        html = send(method, resource, value)
        return html if html
      end

      method = "#{column.to_s}_label"
      if resource.respond_to?(method)
        escape_once resource.send(method)
      else
        html = to_label(value)
        return html if html.html_safe?
        return html_escape(html) if !html&.include?("\n")
        simple_format(html, {}, wrapper_tag: :div)
      end
    end

    def to_label(value, blank = nil)
      return blank if value.blank?
      return safe_join value.map {|v| to_label(v, blank)}, ", " if value.is_a?(Enumerable)
      return I18n.l(value) if value.is_a?(Time) || value.is_a?(Date)
      return value.label if value.respond_to?(:label)
      return value.text if value.respond_to?(:text)
      return value.name if value.respond_to?(:name)
      value.to_s
    end

    def crud_table(columns, resources, actions, options = nil)
      options = (try(:crud_table_options) || {}).deep_merge(options || {})
      options[:class] ||= "table table-striped table-bordered table-vcenter crud-table"
      options[:class] += " modal-table" if modal?
      header_options = options[:header] || {}
      m = model
      if options[:model]
        m = options[:model]
        params = options[:params] ||= {}
        controller = params[:controller] ||= m.model_name.plural
      end
      sort = options[:sort] != false
      remote = options.has_key?(:remote) ? options[:remote] : @remote
      multiple = options.has_key?(:multiple) ? options[:multiple] : self.params[:multiple] == "true"
      selectable = options.has_key?(:selectable) ? options[:selectable] : modal?
      table = content_tag(:table, class: options[:class]) do
        content_tag(:thead) do
          content_tag(:tr) do
            if selectable
              if multiple
                input = modal_selector(id: "selector-all", type: "checkbox", value: 0, "data-label": "all")
                concat content_tag(:th, input, class: "selector-all")
              else
                concat content_tag(:th, nil, class: "selector")
              end
            end
            columns.each do |column|
              label = m.human_attribute_name(column)
              label = link_to_sort(column, label: label, remote: remote, params: params) if sort
              concat content_tag(:th, label, header_options[column])
            end
            concat content_tag(:th, nil, class: "crud-actions") unless actions.empty?
          end
        end + content_tag(:tbody) do
          resources.each.with_index do |resource, index|
            concat(content_tag(:tr) do
              concat modal_selector_input(resource, options.merge({id: "modal_selector_#{index}", multiple: multiple})) if selectable
              columns.each do |column|
                concat content_tag(:td, column_html(resource, column, controller))
              end
              unless actions.empty?
                concat(content_tag(:td) do
                  actions.each do |action|
                    concat link_to_action(action, resource, remote: remote, params: params)
                  end
                end)
              end
            end)
          end
        end
      end

      content_tag(:div, table, class: "table-responsive")
    end

    def modal_selector_input(resource, options = {})
      select_type = options[:multiple] ? "checkbox" : "radio"
      select_name = options.has_key?(:selector_name) ? options[:selector_name] : "modal-select"
      select_name += "[]" if options[:multiple]
      data = serializer.new(resource, scope: serialization_scope).as_json
      data[:label] ||= to_label(resource)
      input_options = { id: options[:id], type: select_type, name: select_name, value: resource.id, data: { resource: data } }
      content_tag(:td, modal_selector(input_options), class: "selector")
    end

    def modal_selector(options)
      content_tag(:input, nil, options)
    end

    def modal_target
      params.has_key?(:modal_target) ? params[:modal_target] : "modal_target"
    end

    def script_for_index_selector(options = {})
      table_selector = ".modal-table"
      table_selector = ".#{options[:class]}" if options.has_key?(:class)
      table_selector = "##{options[:id]}" if options.has_key?(:id)
      multiple = options.has_key?(:multiple) ? options[:multiple] : params[:multiple] == "true"
      exclude_script_tag = options[:exclude_script_tag].present?
      script = <<-SCRIPT
        $(function() {
          $("#term").focus();
          var modalTarget = $("##{modal_target}");
          var fields = (modalTarget.data("value_method") || "id").split(".");
          function getValue(data) {
            return fields.reduce(function(value, field) { return value == null ? value : value[field]; }, data);
          }

          var table = $("#{table_selector}");
          var selectors = table.find("td.selector").find("input:radio, input:checkbox");
          var selected = modalTarget.data("selected") || [];
          var changed = {};
          Array.isArray(selected) && selected.forEach(function(data) { changed[getValue(data)] = data; });
          modalTarget.data("changed", changed);
          var multiple = #{multiple};
          var allSelector = table.find(".selector-all input:checkbox");

          selectors.on("change", function(e) {
            var data = $(this).data("resource");
            if (!multiple) { changed = {}; }
            if ($(this).prop("checked")) {
              changed[getValue(data)] = data;
            } else {
              delete changed[getValue(data)];
            }
            modalTarget.data("changed", changed);
            modalTarget.data("selected", Object.keys(changed).map(function(key) { return changed[key]; }));
            allSelector.trigger("update");
            e.stopPropagation();
          });

          allSelector.on("change", function(e) {
            var checked = $(this).prop("checked");
            selectors.each(function() {
              var self = $(this);
              var data = self.data("resource");
              self.prop("checked", checked);
              if (checked) {
                changed[getValue(data)] = data;
              } else {
                delete changed[getValue(data)];
              }
            });
            modalTarget.data("changed", changed);
            e.stopPropagation();
          }).on("update", function() {
            var checked = selectors.length > 0 && selectors.not(":checked").length == 0;
            allSelector.prop("checked", checked);
          });

          selectors.each(function() {
            var data = $(this).data("resource");
            if (changed[getValue(data)]) $(this).prop("checked", true);
          });
          allSelector.trigger("update");

          #{options[:additional_script]}
        });
      SCRIPT

      exclude_script_tag ? raw(script) : javascript_tag(script)
    end

    def index_crud_table_options
      method = find_method(:crud_table_options)
      options = send(method) if method && method != :crud_table_options
      options || {}
    end

    def crud_form(resource, options = nil, &block)
      method = crud_action == :update ? :put : :post
      url = url_for(stored_params(action: crud_action, only_path: true))
      options = {
        remote: @remote,
        as: model_key,
        method: method,
        url: url,
        html: { class: "col-sm-12" }
      }.merge(options || {})

      send(:simple_form_for, resource, options, &block)
    end

    def simple_form_input(f, column, options = nil)
      if html = call_method_for_column(column, :input, f)
        return html
      end

      options = input_options(f, column).deep_merge(options || {})
      method = Crud::ModelReflection[f.object].association_key?(column) ? :association : :input
      f.send(method, column, options)
    end

    #
    # 入力フィールドの表示オプション.
    # カラムごとにsimple_formのinputに渡すオプションを指定できる．
    # 例えばUsersControllerのformでnameのinputに渡すオプションは
    # def users_name_input_options または name_input_options
    # を定義して指定する規約にしている．
    #
    def input_options(f, column)
      default = {}
      case Crud::ModelReflection[f.object].column_type(column)
      when :boolean
        default[:wrapper] = :vertical_boolean
      when :datetime, :timestamp
        default[:as] = :bootstrap_datetimepicker
      when :date
        default[:as] = :bootstrap_datepicker
      when :time
        default[:as] = :bootstrap_timepicker
      end
      options = call_method_for_column(column, :input_options) || {}
      options = default.merge(options)
      options
    end

    def password_input_options
      {input_html: {autocomplete: :off}}
    end

    def password_confirmation_input_options
      password_input_options
    end

    def search_input_options(f, column)
      options = call_method_for_column(column, :search_input_options) || {}
      input_options(f, column).merge(label: false, wrapper: :input_only).deep_merge(options)
    end

    def advanced_search_input(f, column)
      values = Array(search_values[column])
      op = search_operators[column]
      selected_operator = SearchQuery::Operator[op].try(:operator_name)
      selected_operator ||= "equals" if !op && values.first.present?
      if html = call_method_for_column(column, :search_input, f, selected_operator, *values)
        return html
      end
      column_size_class = @remote ? "col-sm-3" : "col-sm-2"

      ref = ModelReflection[f.object.class]
      type = ref.column_type(column)
      return nil unless operators = call_method_for_column(column, :search_operator_options) || SearchQuery::Operator.available_for(type)
      options = search_input_options(f, column)
      is_boolean = options[:as] ? options[:as] == :boolean : type == :boolean
      is_select = options[:as] ? [:select, :select2].include?(options[:as]) : [:enum, :belongs_to, :has_many, :has_and_belongs_to_many].include?(type)
      is_multiple = is_select && (options.has_key?(:multiple) ? options[:multiple] : [:has_many, :has_and_belongs_to_many].include?(type))
      div_options = { class: "form-group row" }
      div_options[:style] = "display: none;" if op.blank? && values.empty?
      content_tag :div, div_options do
        concat f.label( column, required: false, class: "#{column_size_class} col-form-label")
        concat content_tag(:div, search_operator_select("op[#{column}]", operators, selected_operator), class: column_size_class)
        if args = SearchQuery::Operator[selected_operator].try(:args)
          (0...args).each do |i|
            input_options = options.deep_merge(
              input_html: { name: "v[#{column}][]" },
              wrapper_html: { class: "col-sm" }
            )
            input_options[:input_html][:id] ||= "query_#{column}_#{i}"
            if is_boolean
              input_options[:wrapper] = :input_only_checkbox
              input_options[:input_html][:checked] = ref.cast(:boolean, values)
            elsif is_select
              if is_multiple
                input_options[:selected] = values
              else
                input_options[:selected] = values[i]
                input_options[:include_blank] = true unless input_options.has_key?(:include_blank)
              end
            else
              input_options[:input_html][:value] = values[i]
            end
            method = ref.association_key?(column) && type != :has_one ? :association : :input
            concat f.send(method, column, input_options)
          end
        end
      end
    end

    def search_operator_select(name, operators, selected)
      options = operators.map do |o|
        o = SearchQuery::Operator[o] || o
        o.is_a?(Class) && o < SearchQuery::Operator ? [o.label, o.operator_name] : o
      end
      select_tag(name, options_for_select(options, selected), class: "operator form-control", include_blank: true)
    end

    def translate_wizard_step(step)
      I18n.t(step, scope: [:wizard, controller_path], default: step.to_s.humanize)
    end

    private
    def call_method_for_column(column, suffix, *args)
      method = find_method("#{column}_#{suffix}")
      send(method, *args) if method
    end

    def debug?
      return @debug unless @debug.nil?
      @debug = ENV["CRUD_DEBUG"] == "true"
    end

    def dump_method_info(method_name, prefix = nil)
      if debug? && prefix != "crud"
        exists = respond_to?(method_name)
        debug_info = {method_name: method_name, exists: exists}
        if exists
          value = begin; send(method_name); rescue; end
          debug_info.merge!(class: method(method_name).owner, source_location: method(method_name).source_location, value: value)
        end
        Pry::ColorPrinter.pp(debug_info)
      end
    end

    def find_method(short_method, controller_name = nil)
      c = controller_name ? "#{controller_name.camelize}Controller".constantize : controller.class

      return unless c < Crud::ApplicationController
      while c != Crud::ApplicationController
        prefix = c.name.sub(/Controller$/, "").underscore.gsub("/", "_")
        method = "#{prefix}_#{short_method}"

        dump_method_info(method, prefix)

        return method if respond_to?(method)
        c = c.superclass
      end

      dump_method_info(short_method)

      return short_method if respond_to?(short_method)
      nil
    end
  end
end
