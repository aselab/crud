<% module_namespacing do -%>
module <%= class_name %>Helper
  # simple_formのinputに渡すオプション定義
    # def <%= plural_name %>_<%= model_columns.first || '#{column_name}' %>_input_options
  #   { as: :select2 }
  # end

  # 一覧/詳細画面で表示するHTML
  # def <%= plural_name %>_<%= model_columns.first || '#{column_name}' %>_html(resource, value)
  #   link_to value, resource
  # end
end
<% end -%>
