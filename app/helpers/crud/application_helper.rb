module Crud
  module ApplicationHelper
    def link_to_sort(key)
      label = model.human_attribute_name(key)
      if sort_key?(key)
        focus = sort_key == key.to_sym
        current = sort_order
        order = focus && current == :asc ? :desc : :asc
        p = params.dup.update(:sort_key => key.to_s, :sort_order => order.to_s)
        link_to(label, p, :class => focus ? current.to_s : nil)
      else
        label
      end
    end

    def link_to_action(action, resource = nil, params = {})
      if can?(action, resource)
        label = action == :new ?
          t("crud.action_title.new", :name => model_name) :
          t("crud.action." + action.to_s)

        options = {:class => "btn"}
        if action == :destroy
          options[:method] = :delete
          options[:data] = { :confirm => t("crud.message.are_you_sure") }
          options[:class] += " btn-danger"
        end

        url = stored_params(:action => action, :id => resource).merge(params)

        link_to(label, url, options)
      end
    rescue ActionController::RoutingError
    end

    #
    # Ajaxによる作成/更新リンク作成用メソッド。
    # フォームをモーダル表示して作成/更新に成功したら、
    # ブロックで指定したJavaScriptコールバック関数を実行する。
    # コールバック関数の第2引数には、作成/更新したレコードデータが入っている。
    # 
    #  <%= link_to_modal("ラベル", new_item_path) do %>
    #    function(event, data) { console.log(data); }
    #  <% end %>
    #
    def link_to_modal(label, path, html_options = nil, &block)
      html_options ||= {}
      id = html_options[:id] ||= "modal-form-#{rand(100000000)}"
      data = html_options[:data] ||= {}
      data[:toggle] = "modal-form"
      html = link_to(label, path, html_options)
      html += javascript_tag <<-EOT if block
        $(function() {$("##{id}").on("crud:success", #{capture(&block)})});
      EOT
      html
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

    def simple_form_input(f, column, options = nil)
      if html = call_method_for_column(:input, column, f)
        return html
      end

      options ||= input_options(column) || {}
      options[:collection] = [] if options[:as] == :select2 && (options[:ajax] || options[:url].present?)
      return f.association column, options if association_key?(column)

      case f.object.class.columns_hash[column.to_s].try(:type)
      when :datetime, :timestamp
        options[:as] ||= :bootstrap_datetimepicker
      when :date
        options[:as] ||= :bootstrap_datepicker
      when :time
        options[:as] ||= :bootstrap_timepicker
      end
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
      short_method = column.to_s + "_" + suffix.to_s
      method = params[:controller] + "_" + short_method
      return send(method, *args) if respond_to?(method)
      return send(short_method, *args) if respond_to?(short_method)
      nil
    end
  end
end
