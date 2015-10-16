module Crud
  module ApplicationHelper
    def link_to_sort(key)
      label = model.human_attribute_name(key)
      if sort_key?(key)
        focus = sort_key == key.to_sym
        current = sort_order
        order = focus && current == :asc ? :desc : :asc
        icon = current == :asc ? "fa-sort-asc" : "fa-sort-desc"
        p = params.dup.update(:sort_key => key.to_s, :sort_order => order.to_s)
        link = link_to(label, p, remote: @remote)
        if focus
          link + content_tag(:i, nil, :class => "fa " + icon)
        else
          link
        end
      else
        label
      end
    end

    def link_to_action(action, resource = nil, params = {}, &block)
      url_params = stored_params(:action => action, :id => resource).merge(params)
      method = find_method("link_to_#{action}")
      return send(method, url_params) if method

      begin
        if can?(action, resource)
          options = {remote: @remote}
          if action == :destroy
            options[:method] = :delete
            options[:data] = { :confirm => t("crud.message.are_you_sure") }
            options[:class] = "btn btn-danger"
          else
            options[:class] = "btn btn-default"
          end

          if block
            link_to(url_params, options, &block)
          else
            label = action == :new ?
              t("crud.action_title.new", :name => model_name) :
              t("crud.action." + action.to_s)
            link_to(label, url_params, options)
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
    def column_html(resource, column)
      return nil unless resource && column
      value = resource.send(column)
      if html = call_method_for_column(:html, column, resource, value)
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
      if html = call_method_for_column(:input, column, f)
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
    def input_options(column)
      call_method_for_column(:input_options, column)
    end

    def password_input_options
      {:input_html => {:autocomplete => :off}}
    end

    def password_confirmation_input_options
      password_input_options
    end

    private
    def call_method_for_column(suffix, column, *args)
      method = find_method(column.to_s + "_" + suffix.to_s)
      send(method, *args) if method
    end

    def find_method(short_method)
      method = params[:controller].gsub("/", "_") + "_" + short_method
      return method if respond_to?(method)
      return short_method if respond_to?(short_method)
      nil
    end
  end
end
