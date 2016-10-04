module Ar::GroupsHelper
  def ar_groups_permissions_input(f)
    content_tag :div, class: "form-group" do
      f.label(:permissions, class: "control-label") +
      f.simple_fields_for(:permissions) do |form|
        render "permission_fields", f: form
      end + content_tag(:div) do
        link_to_add_association(f, :permissions) do
          content_tag :i, nil, class: "fa fa-plus button-icon"
        end
      end
    end
  end
end
