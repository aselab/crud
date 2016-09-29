class Ar::CompaniesController < Crud::ApiController
  permit_keys :name
end
