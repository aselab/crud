class CreateArUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :ar_users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.date :birth_date

      t.timestamps
    end
  end
end
