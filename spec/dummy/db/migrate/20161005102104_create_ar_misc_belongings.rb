class CreateArMiscBelongings < ActiveRecord::Migration[5.0]
  def change
    create_table :ar_misc_belongings do |t|
      t.references :misc, foreign_key: true
      t.string :name
    end
  end
end
