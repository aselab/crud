class MiscHabtmsController < Crud::ApplicationController
  permit_keys :name, misc_ids: []

  protected
  def model_columns
    [:name, :miscs]
  end
end
