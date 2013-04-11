module Crud
  module ApplicationHelper
    def sort_link_to(key)
      label = model.human_attribute_name(key)
      if column_key?(key) || association_key?(key)
        focus = params[:sort_key] == key.to_s
        current = params[:sort_order]
        order = focus && current == "asc" ? "desc" : "asc"
        p = params.dup.update(:sort_key => key.to_s, :sort_order => order)
        icon = focus && current ? content_tag(:i, nil, :class =>
          (current == "asc" ? "icon-caret-up" : "icon-caret-down")) : nil
        link_to(p) { label.html_safe + icon }
      else
        label
      end
    end

    def to_label(value, blank = nil)
      return blank if value.blank?
      return value.map {|v| to_label(v)} if value.respond_to?(:map)
      return value.label if value.respond_to?(:label)
      return value.name if value.respond_to?(:name)
      return I18n.l(value) if value.is_a?(Time) || value.is_a?(Date)
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
