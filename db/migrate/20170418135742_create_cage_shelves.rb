class CreateCageShelves < ActiveRecord::Migration[4.2]
  def change
    create_table :cage_shelves do |t|
      t.integer :cage_id, limit: 8
      t.integer :mdpi_barcode, limit: 8
      t.string :identifier
      t.text :notes
      t.timestamps null: false
    end
  end
end
