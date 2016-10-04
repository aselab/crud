class CreateArPermissions < ActiveRecord::Migration
  def change
    create_table :ar_permissions do |t|
      t.references :permissible, polymorphic: true, index: true, null: false
      t.references :user, index: true, null: false
      t.integer :flags, null: false
    end
  end
end
