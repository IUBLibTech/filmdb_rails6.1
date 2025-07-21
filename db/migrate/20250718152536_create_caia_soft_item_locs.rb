class CreateCaiaSoftItemLocs < ActiveRecord::Migration[8.0]
  def change
    create_table :caia_soft_item_locs do |t|
      t.bigint :iu_barcode
      t.integer :physical_object_id, limit: 8
      t.string :status
      t.string :container
      t.string :address
      t.string :location
      t.string :footprint
      t.string :container_type
      t.string :collection
      t.string :material
      t.string :accession_date
      t.string :last_status_update
      t.timestamps

      t.index :iu_barcode, unique: true
      t.index :physical_object_id, unique: true
    end
  end
end
