class CreatePhysicalObjectOldBarcodes < ActiveRecord::Migration[4.2]
  def change
    create_table :physical_object_old_barcodes do |t|
      t.integer :physical_object_id, limit: 8
      t.integer :iu_barcode, limit: 8
      t.timestamps
    end
  end
end
