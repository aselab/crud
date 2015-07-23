class AddColumnsToUsers < ActiveRecord::Migration
  def change
    remove_column :users, :group_id
    add_column :users, :number, :integer
  end
end
