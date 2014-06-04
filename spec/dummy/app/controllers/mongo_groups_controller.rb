class MongoGroupsController < Crud::ApplicationController
  permit_keys :name
end
