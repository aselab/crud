class MongoUsersController < Crud::ApplicationController
  permit_keys :name, :birth_date
end
