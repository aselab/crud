module UsersHelper
  def users_name_html(resource, value)
    link_to value, resource, remote: @remote
  end

  def users_group_html(resource, value)
    link_to value.name, value, remote: @remote if value
  end
end
