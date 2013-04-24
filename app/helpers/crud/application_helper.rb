module Crud
  module ApplicationHelper
    def link_to_sort(key)
      label = model.human_attribute_name(key)
      if column_key?(key) || association_key?(key)
        focus = params[:sort_key] == key.to_s
        current = params[:sort_order]
        order = focus && current == "asc" ? "desc" : "asc"
        p = params.dup.update(:sort_key => key.to_s, :sort_order => order)
        link_to(label, p, :class => focus ? current : nil)
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
    # カラムのhtml表示出力用メソッド.
    # 以下の優先順で表示する。
    # 1. #{model_name}_#{column_name}_html という名前のhelperメソッド
    # 2. #{column_name}_html という名前のhelperメソッド
    # 3. #{column_name}_label という名前のmodelメソッド
    #
    def column_html(resource, column)
      return nil unless resource && column
      short_method = "#{column.to_s}_html"
      method = model.model_name.underscore + "_" + short_method
      return send(method) if respond_to?(method)
      return send(short_method) if respond_to?(short_method)

      method = "#{column.to_s}_label"
      value = resource.send(resource.respond_to?(method) ? method : column)
      simple_format to_label(value)
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
      options ||= {}
      if association_key?(column)
        f.association column, options
      else
        f.input column, options
      end
    end

    #
    # 入力フィールドの表示オプション.
    # カラムごとにsimple_formのinputに渡すオプションを指定できる．
    # 例えばUser#nameカラムのinputに渡すオプションは
    # def user_name_input_options または name_input_options
    # を定義して指定する規約にしている．
    #
    def input_options(column)
      short_method = column.to_s + "_input_options"
      method = model.model_name.underscore + "_" + short_method
      return send(method) if respond_to?(method)
      return send(short_method) if respond_to?(short_method)
      nil
    end

    def password_input_options
      {:input_html => {:autocomplete => :off}}
    end

    def password_confirmation_input_options
      password_input_options
    end

  end
end
