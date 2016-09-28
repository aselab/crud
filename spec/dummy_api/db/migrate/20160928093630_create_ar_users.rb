class CreateArUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :ar_users do |t|
      t.references :company, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :email
      t.integer :age

      t.timestamps
    end
  end
end
