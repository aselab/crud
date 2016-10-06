<% if namespaced? -%>
require_dependency "<%= namespaced_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= class_name %>Controller < Crud::<%= options[:api] ? "Api" : "Application" %>Controller
  permit_keys <%= permit_keys.map{|key| ":" + key}.join(", ") %>

  protected
  # 表示/更新対象のカラムリスト
  def model_columns
    <%= model_columns.inspect %>
  end

  # 一覧表示のカラムリスト
  def columns_for_index
    model_columns
  end
end
<% end -%>
