class RemoveTitleVersionFromPhysicalObject < ActiveRecord::Migration[4.2]
  def up
    remove_column :physical_objects, :title_version
  end

  def down
    add_column :physical_objects, :title_version, :string
  end
end
