class RemoveSoundConfigSingleFromPhysicalObject < ActiveRecord::Migration[4.2]
  def up
    remove_column :physical_objects, :sound_configuration_single
  end

  def down
    add_column :physical_objects, :sound_onfiguration_single, :boolean
  end
end
