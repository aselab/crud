module Ar::UsersHelper
  def ar_users_name_search_input(f, operator, *values)
    content_tag :div, class: "form-group" do
      concat f.label(:name, class: "col-sm-2 control-label")
      concat content_tag(:div, search_operator_select("op[name]", ["equals", "contains"], operator), class: "col-sm-2")
      if operator
        input = text_field_tag "v[name]", values[0], class: "form-control"
        concat content_tag(:div, input, class: "col-sm-8")
      end
    end
  end

  def ar_users_age_search_input(f, operator, *values)
    content_tag :div, class: "form-group" do
      concat f.label(:age, class: "col-sm-2 control-label")
      concat content_tag(:div, search_operator_select("op[age]", ["equals", "between"], operator), class: "col-sm-2")
      case operator
      when "equals"
        input = number_field_tag "v[age]", values[0], class: "form-control"
        concat content_tag(:div, input, class: "col-sm-8")
      when "between"
        input = number_field_tag "v[age][]", values[0], id: nil, class: "form-control"
        concat content_tag(:div, input, class: "col-sm-4")
        input = number_field_tag "v[age][]", values[1], id: nil, class: "form-control"
        concat content_tag(:div, input, class: "col-sm-4")
      end
    end
  end
end
