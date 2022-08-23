class AddActiveComponentGroupIdToPhysicalObject < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :component_group_id, :integer, limit: 8
  end
end
