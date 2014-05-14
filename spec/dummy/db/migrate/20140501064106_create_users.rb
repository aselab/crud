class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.date :birth_date
      t.integer :group_id

      t.timestamps
    end
  end
end
