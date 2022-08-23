# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggerPhysicalObjectsUpdate < ActiveRecord::Migration[4.2]
  def up
    create_trigger("physical_objects_after_update_of_iu_barcode_row_tr", :generated => true, :compatibility => 1).
        on("physical_objects").
        after(:update).
        of(:iu_barcode) do
      "INSERT INTO physical_object_old_barcodes(physical_object_id, iu_barcode) VALUES(OLD.id, OLD.iu_barcode);"
    end
  end

  def down
    drop_trigger("physical_objects_after_update_of_iu_barcode_row_tr", "physical_objects", :generated => true)
  end
end
