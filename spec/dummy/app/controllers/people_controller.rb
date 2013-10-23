class PeopleController < Crud::ApplicationController
  default_sort_key :position

  protected
  def columns_for_index
    [:label, :position]
  end

  def sort_by_label(order)
    self.resources = resources.order("name #{order}")
  end

  def search_by_label(term)
    ["name like ?", "%#{term}%"]
  end

  def sort_by_position(order)
    self.resources = resources.order("position is null #{order}, position #{order}")
  end
end
