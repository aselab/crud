class Ar::UsersController < Crud::ApplicationController
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

  def search_by_name(term)
    ["last_name LIKE :term OR first_name LIKE :term", term: "%#{term}%"]
  end

  def search_by_age(term)
    age = Integer(term)
    {birth_date: ((age + 1).years.ago + 1.day).to_date..(age.years.ago).to_date}
  rescue
  end

  def sort_by_name(order)
    "last_name #{order}, first_name #{order}"
  end

  def sort_by_age(order)
    reverse_order = order == :asc ? :desc : :asc
    "birth_date #{reverse_order}"
  end

  class Authorization < Crud::Authorization::Default
    def manage?(user)
      current_user.try(:is_admin) || user == current_user
    end

    def destroy?(user)
      manage?(user) && user != current_user
    end
  end
end
