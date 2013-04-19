class CreatePermissions < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.references :permissible, :polymorphic => true, :null => false
      t.references :principal, :null => false
      t.integer :flags, :null => false
    end
    add_index :permissions, [:permissible_id, :permissible_type]
    add_index :permissions, :principal_id
  end
end
