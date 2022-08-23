class AddOriginalCameraToPhysicalObject < ActiveRecord::Migration[4.2]
  def up
    add_column :physical_objects, :generation_original_camera, :boolean, null: true
    remove_column :physical_objects, :generation_edited_camera_original
  end

  def down
    add_column :physical_objects, :generation_edited_camera_original, :boolean, null: true
    remove_column :physical_objects, :generation_original_camera
  end
end
