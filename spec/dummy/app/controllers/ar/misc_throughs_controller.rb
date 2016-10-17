class Ar::MiscThroughsController < Crud::ApplicationController
  permit_keys :misc_belonging_id, :name

  protected
  def model_columns
    [:misc_belonging, :name]
  end
end
