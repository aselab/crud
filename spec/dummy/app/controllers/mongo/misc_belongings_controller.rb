class Mongo::MiscBelongingsController < Crud::ApplicationController
  permit_keys :misc_id, :name

  protected
  # 表示/更新対象のカラムリスト
  def model_columns
    [:misc, :name]
  end

  # 一覧表示のカラムリスト
  def columns_for_index
    model_columns
  end

  class Authorization < Crud::Authorization::Default
  end
end
