class AddAnamorphicAndTrackCountToPhysicalObject < ActiveRecord::Migration[4.2]
  def up
    add_column :physical_objects, :anamorphic, :string
    add_column :physical_objects, :track_count, :integer
  end

  def down
    remove_column :physical_objects, :anamorphic
    remove_column :physical_objects, :track_count
  end
end
