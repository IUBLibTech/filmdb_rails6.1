class RemovePhysicalObjectOldBarcodeIuBarcodeIndex < ActiveRecord::Migration[4.2]
  def change
    remove_index :physical_object_old_barcodes, :iu_barcode
  end
end
