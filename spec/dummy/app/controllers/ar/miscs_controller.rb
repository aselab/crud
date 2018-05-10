class Ar::MiscsController < MiscsController
  permit_keys :file

  protected

  def model_columns
    [:boolean, :string, :integer, :float, :decimal, :datetime, :date, :time, :enumerized, :file, :misc_belongings, :misc_habtms]
  end

  def columns_for_index
    model_columns + [:misc_throughs]
  end
end
