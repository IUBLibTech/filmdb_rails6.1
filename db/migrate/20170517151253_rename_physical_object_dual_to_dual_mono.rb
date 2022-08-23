class RenamePhysicalObjectDualToDualMono < ActiveRecord::Migration[4.2]
  def up
    rename_column :physical_objects, :sound_configuration_dual, :sound_configuration_dual_mono
  end

  def down
		rename_column :physical_objects, :sound_configuration_dual_mono, :sound_configuration_dual
  end
end
