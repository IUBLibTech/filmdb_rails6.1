class CreateTitleLocations < ActiveRecord::Migration[4.2]
  def change
    create_table :title_locations do |t|
      t.integer :title_id, limit: 8
      t.string :location, null: false
      t.timestamps
    end
  end
end
