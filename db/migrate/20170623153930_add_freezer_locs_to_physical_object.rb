class AddFreezerLocsToPhysicalObject < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :in_freezer, :boolean, default: false
    add_column :physical_objects, :awaiting_freezer, :boolean, default: false
  end
end
