class CreatePermissions < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.references :permissible, polymorphic: true, null: false
      t.references :user, null: false
      t.integer :flags, null: false
    end
    add_index :permissions, [:permissible_id, :permissible_type], name: "index_permissible_keys"
    add_index :permissions, :user_id
  end
end
