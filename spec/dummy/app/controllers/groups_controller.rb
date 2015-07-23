class GroupsController < Crud::ApplicationController
  permit_keys :name
end
