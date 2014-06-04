class MongoGroupsController < Crud::ApplicationController
  permit_keys :name

  protected
  def index_actions
    [:show, :edit, :destroy, :resources]
  end
end
