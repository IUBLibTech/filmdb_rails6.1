class RemoveHairTriggerTrigger < ActiveRecord::Migration[4.2]

  # Hairtrigger seems to be having problems with the database index I needed to remove for physical_object_old_barcodes so
  # now doing the recording of changed barcodes manually. Need to remove the hairtrigger generated trigger because it results
  # in sporadic duplication of the barcode change.

  def up
    drop_trigger("physical_objects_after_update_of_iu_barcode_row_tr", "physical_objects", :generated => true)
  end

  def down
    create_trigger("physical_objects_after_update_of_iu_barcode_row_tr", :generated => true, :compatibility => 1).
      on("physical_objects").
      after(:update).
      of(:iu_barcode) do
      "INSERT INTO physical_object_old_barcodes(physical_object_id, iu_barcode) VALUES(OLD.id, OLD.iu_barcode);"
    end
  end
end
