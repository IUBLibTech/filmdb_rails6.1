class AddUniqueToBarcodes < ActiveRecord::Migration[4.2]
  def change
    add_index :physical_objects, [:iu_barcode, :mdpi_barcode], unique: true
    add_index :cage_shelves, :mdpi_barcode, unique: true
    add_index :physical_object_old_barcodes, :iu_barcode, unique: true
  end
end
