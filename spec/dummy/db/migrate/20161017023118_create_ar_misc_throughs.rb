class CreateArMiscThroughs < ActiveRecord::Migration[5.0]
  def change
    create_table :ar_misc_throughs do |t|
      t.references :misc_belonging
      t.string :name
    end
  end
end
