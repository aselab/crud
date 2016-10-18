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

  def advanced_search_by_name(operator, value)
    operator ||= "contains"
    case operator
    when "equals"
      last, first = value.to_s.split(" ")
      { last_name: last, first_name: first}
    when "contains"
      ["last_name LIKE :value OR first_name LIKE :value", value: "%#{value}%"]
    else
      "0 = 1"
    end
  end

  def search_by_age(term)
    age = Integer(term)
    advanced_search_by_age("equals", age)
  rescue
  end

  def advanced_search_by_age(operator, *values)
    v1, v2 = values.map {|v| Integer(v)}
    case operator
    when "equals"
      {birth_date: ((v1 + 1).years.ago + 1.day).to_date..(v1.years.ago).to_date}
    when "between"
      {birth_date: ((v2 + 1).years.ago + 1.day).to_date..(v1.years.ago + 1.day).to_date}
    else
      "0 = 1"
    end
  rescue
    "0 = 1"
  end

  def sort_by_name(order)
    "last_name #{order}, first_name #{order}"
  end

  def sort_by_age(order)
    reverse_order = order == :asc ? :desc : :asc
    "birth_date #{reverse_order}"
  end
end
