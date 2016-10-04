class Ar::GroupsController < Crud::ApplicationController
  permit_keys :name, permissions_attributes: [:_destroy, :id, :user_id, :flags]

  protected
  # 表示/更新対象のカラムリスト
  def model_columns
    [:name, :permissions]
  end

  # 一覧表示のカラムリスト
  def columns_for_index
    [:name]
  end

  class Authorization < Crud::Authorization::Default
  end
end
