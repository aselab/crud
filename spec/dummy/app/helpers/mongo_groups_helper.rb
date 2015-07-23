module MongoGroupsHelper
  def mongo_groups_link_to_resources(params)
    link_to "Resources", mongo_group_mongo_resources_path(params[:id]), class: "btn btn-default"
  end
end
