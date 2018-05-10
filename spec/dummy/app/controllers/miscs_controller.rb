class MiscsController < Crud::ApplicationController
  permit_keys :boolean, :string, :integer, :float, :decimal, :datetime, :date, :time, :enumerized, misc_belonging_ids: [], misc_habtm_ids: []

  protected
  # 表示/更新対象のカラムリスト
  def model_columns
    [:boolean, :string, :integer, :float, :decimal, :datetime, :date, :time, :enumerized, :misc_belongings, :misc_habtms]
  end
end
