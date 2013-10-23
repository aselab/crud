class PeopleController < Crud::ApplicationController
  default_sort_key :position

  protected
  def columns_for_index
    [:label, :position]
  end

  def search_by_label(term)
    ["name like ?", "%#{term}%"]
  end

  def search_by_position(term)
    {:position => term}
  end

  def sort_by_label(order)
    "name #{order}"
  end

  def sort_by_position(order)
    "position is null #{order}, position #{order}"
  end
end
