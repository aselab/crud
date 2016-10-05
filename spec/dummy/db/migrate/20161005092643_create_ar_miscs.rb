class CreateArMiscs < ActiveRecord::Migration[5.0]
  def change
    create_table :ar_miscs do |t|
      t.boolean :boolean
      t.string :string
      t.integer :integer
      t.float :float
      t.datetime :datetime
      t.date :date
      t.time :time
    end
  end
end
