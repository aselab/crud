class CreateArMiscHabtms < ActiveRecord::Migration[5.0]
  def change
    create_table :ar_misc_habtms do |t|
      t.string :name
    end

    create_table :ar_misc_habtms_miscs, id: false do |t|
      t.references :misc
      t.references :misc_habtm
    end
  end
end
