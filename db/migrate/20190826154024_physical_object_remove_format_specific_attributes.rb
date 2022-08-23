class PhysicalObjectRemoveFormatSpecificAttributes < ActiveRecord::Migration[4.2]
  # addition fields that need to be removed from the PhysicalObject super class - these are holdovers from when conditions
  # were simply boolean values on PhysicalObjects. They've since been converted to fully relational ActiveModels
  def change
    remove_column :physical_objects, :format
    remove_column :physical_objects, :color_fade
    remove_column :physical_objects, :perforation_damage
    remove_column :physical_objects, :water_damage
    remove_column :physical_objects, :warp
    remove_column :physical_objects, :brittle
    remove_column :physical_objects, :splice_damage
    remove_column :physical_objects, :dirty
    remove_column :physical_objects, :peeling
    remove_column :physical_objects, :tape_residue
    remove_column :physical_objects, :broken
    remove_column :physical_objects, :tearing
    remove_column :physical_objects, :poor_wind
    remove_column :physical_objects, :not_on_core_or_reel
    remove_column :physical_objects, :scratches
    remove_column :physical_objects, :lacquer_treated
    remove_column :physical_objects, :replasticized
    remove_column :physical_objects, :spoking
    remove_column :physical_objects, :dusty
    remove_column :physical_objects, :rusty
    remove_column :physical_objects, :channeling
  end
end
