class Ar::MiscsController < Crud::ApplicationController
  permit_keys :boolean, :string, :integer, :float, :datetime, :date, :time, :enumerized, misc_belonging_ids: []

  protected
  # 表示/更新対象のカラムリスト
  def model_columns
    [:boolean, :string, :integer, :float, :datetime, :date, :time, :enumerized, :misc_belongings]
  end

  # 一覧表示のカラムリスト
  def columns_for_index
    model_columns
  end
end
