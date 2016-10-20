class UsersController < Crud::ApplicationController
  permit_keys :first_name, :last_name, :email, :birth_date

  default_sort_key :age
  default_sort_order :desc

  protected
  def model_columns
    [:last_name, :first_name, :email, :birth_date]
  end

  def columns_for_index
    [:name, :email, :age]
  end

  def sort_by_name(order)
    "last_name #{order}, first_name #{order}"
  end

  def sort_by_age(order)
    reverse_order = order == :asc ? :desc : :asc
    "birth_date #{reverse_order}"
  end
end
