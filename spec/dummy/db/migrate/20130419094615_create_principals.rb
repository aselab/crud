class CreatePrincipals < ActiveRecord::Migration
  def change
    create_table :principals do |t|
      t.string :type
      t.string :name

      t.timestamps
    end
  end
end
