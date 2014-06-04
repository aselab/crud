class MongoResourcesController < Crud::ApplicationController
  permit_keys :name

  prepend_before_action :find_group

  protected
  def do_filter
    @group.mongo_resources
  end

  def new_resource
    self.resource = @group.mongo_resources.new
  end

  def find_resource
    self.resource = @group.mongo_resources.find(params[:id])
  end

  private
  def find_group
    @group = MongoGroup.find(params[:mongo_group_id])
  end
end
