class CreateArCompanies < ActiveRecord::Migration[5.0]
  def change
    create_table :ar_companies do |t|
      t.string :name

      t.timestamps
    end
  end
end
