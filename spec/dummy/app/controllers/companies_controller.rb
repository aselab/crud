class CompaniesController < Crud::ApplicationController
  permit_keys :name, :user_ids => []

  def columns_for_index
    [:name]
  end

  def columns_for_show
    [:name, :users]
  end

  def columns_for_create
    columns_for_show
  end

  def columns_for_update
    columns_for_create
  end
end
