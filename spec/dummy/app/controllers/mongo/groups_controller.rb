class Mongo::GroupsController < Crud::ApplicationController
  permit_keys :name

  protected
  # 表示/更新対象のカラムリスト
  def model_columns
    [:name]
  end

  # 一覧表示のカラムリスト
  def columns_for_index
    model_columns
  end
end
