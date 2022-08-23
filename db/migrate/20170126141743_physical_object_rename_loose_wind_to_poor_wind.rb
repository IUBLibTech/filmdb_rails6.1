class PhysicalObjectRenameLooseWindToPoorWind < ActiveRecord::Migration[4.2]
  def up
    rename_column :physical_objects, :loose_wind, :poor_wind
  end

  def down
    rename_column :physical_objects, :poor_wind, :loose_wind
  end
end
