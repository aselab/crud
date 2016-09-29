class Ar::UsersController < Crud::ApiController
  permit_keys :company_id, :first_name, :last_name, :age

  default_sort_key :age
  default_sort_order :desc

  protected
  def model_columns
    [:company, :last_name, :first_name, :age]
  end

  def columns_for_index
    [:company, :name, :age]
  end
end
