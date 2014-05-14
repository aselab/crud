module UsersHelper
  def users_name_html(resource, value)
    link_to value, resource
  end

  def users_group_html(resource, value)
    link_to value.name, value if value
  end
end
