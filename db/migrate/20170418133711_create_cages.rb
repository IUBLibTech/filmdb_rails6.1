class CreateCages < ActiveRecord::Migration[4.2]
  def change
    create_table :cages do |t|
      t.string :identifier
      t.text :notes
      t.integer :top_shelf_id, limit: 8
      t.integer :middle_shelf_id, limit: 8
      t.integer :bottom_shelf_id, limit: 8
      t.timestamps
    end
  end
end
