class Mongo::UsersController < Crud::ApplicationController
  permit_keys :first_name, :last_name, :email, :birth_date

  protected
  # 表示/更新対象のカラムリスト
  def model_columns
    [:first_name, :last_name, :email, :birth_date]
  end

  # 一覧表示のカラムリスト
  def columns_for_index
    model_columns
  end
end
