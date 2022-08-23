class IndexPhysicalObjectsAndSpecifics < ActiveRecord::Migration[4.2]
  def change
    add_index :physical_objects, [:actable_id, :actable_type], unique: true
  end
end
