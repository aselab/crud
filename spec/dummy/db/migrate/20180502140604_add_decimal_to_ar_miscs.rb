class AddDecimalToArMiscs < ActiveRecord::Migration[5.2]
  def change
    add_column :ar_miscs, :decimal, :decimal
  end
end
