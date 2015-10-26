module Crud
  module ApplicationHelper
    def link_to_sort(key, options = nil)
      options ||= {}
      label = options.delete(:label) || model.human_attribute_name(key)
      options[:remote] = @remote unless options.has_key?(:remote)
      if sort_key?(key)
        focus = sort_key == key.to_sym
        current = sort_order
        order = focus && current == :asc ? :desc : :asc
        icon = current == :asc ? "fa-sort-asc" : "fa-sort-desc"
        p = options.delete(:params) || params
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

    def link_to_action(action, resource = nil, options = nil, &block)
      options ||= {}
      params = stored_params(action: action, id: resource).merge(options.delete(:params) || {})
      method = find_method(params[:controller], "link_to_#{action}")
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
    def column_html(resource, column, controller = nil)
      return nil unless resource && column
      controller ||= params[:controller]
      value = resource.send(column)
      if html = call_method_for_column(controller, column, :html, resource, value)
        return html
      end

      method = "#{column.to_s}_label"
      if resource.respond_to?(method)
        escape_once resource.send(method)
      else
        simple_format escape_once(to_label(value))
      end
    end

    def to_label(value, blank = nil)
      return blank if value.blank?
      return value.map {|v| to_label(v, blank)} if value.is_a?(Enumerable)
      return I18n.l(value) if value.is_a?(Time) || value.is_a?(Date)
      return value.label if value.respond_to?(:label)
      return value.text if value.respond_to?(:text)
      return value.name if value.respond_to?(:name)
      value.to_s
    end

    def crud_table(columns, resources, actions, options = nil)
      options ||= {}
      options[:class] ||= "table table-striped table-bordered table-vcenter"
      m = model
      if options[:model]
        m = options[:model]
        params = options[:params] ||= {}
        params[:controller] ||= m.model_name.plural
      end
      remote = options.has_key?(:remote) ? options[:remote] : @remote
      content_tag(:table, class: options[:class]) do
        content_tag(:thead) do
          content_tag(:tr) do
            columns.each do |column|
              label = m.human_attribute_name(column)
              concat content_tag(:th, link_to_sort(column, label: label, remote: remote, params: params))
            end
            concat content_tag(:th, nil)
          end
        end + content_tag(:tbody) do
          resources.each do |resource|
            concat(content_tag(:tr) do
              columns.each do |column|
                concat content_tag(:td, column_html(resource, column))
              end
              concat(content_tag(:td) do
                actions.each do |action|
                  concat link_to_action(action, resource, remote: remote, params: params)
                end
              end)
            end)
          end
        end
      end
    end

    def crud_form(resource, options = nil, &block)
      action = resource.new_record? ? :create : :update
      options = {
        remote: @remote,
        as: model_key,
        url: resource.new_record? ?
          stored_params(action: action) :
          stored_params(action: action, id: resource),
        html: { class: "col-sm-9" }
      }.merge(options || {})

      send(:simple_form_for, resource, options, &block)
    end

    def simple_form_input(f, column, options = nil)
      if html = call_method_for_column(params[:controller], column, :input, f)
        return html
      end

      default = {}
      case column_type(column, f.object.class)
      when :boolean
        default = { wrapper: :vertical_boolean }
      when :datetime, :timestamp
        default[:as] = :bootstrap_datetimepicker
      when :date
        default[:as] = :bootstrap_datepicker
      when :time
        default[:as] = :bootstrap_timepicker
      end
      options ||= input_options(column) || {}
      options = default.merge(options)
      options[:collection] = [] if options[:as] == :select2 && (options[:ajax] || options[:url].present?)
      return f.association column, options if association_key?(column)

      f.input column, options
    end

    #
    # 入力フィールドの表示オプション.
    # カラムごとにsimple_formのinputに渡すオプションを指定できる．
    # 例えばUsersControllerのformでnameのinputに渡すオプションは
    # def users_name_input_options または name_input_options
    # を定義して指定する規約にしている．
    #
    def input_options(column, controller = nil)
      controller ||= params[:controller]
      call_method_for_column(controller, column, :input_options)
    end

    def password_input_options
      {input_html: {autocomplete: :off}}
    end

    def password_confirmation_input_options
      password_input_options
    end

    private
    def call_method_for_column(controller, column, suffix, *args)
      method = find_method(controller, "#{column}_#{suffix}")
      send(method, *args) if method
    end

    def find_method(controller, short_method)
      method = controller.gsub("/", "_") + "_" + short_method
      return method if respond_to?(method)
      return short_method if respond_to?(short_method)
      nil
    end
  end
end
