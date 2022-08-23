class CreateComponentGroupPhysicalObjects < ActiveRecord::Migration[4.2]
  def change
    create_table :component_group_physical_objects do |t|
      t.integer :component_group_id, limit: 8
      t.integer :physical_object_id, limit: 8
      t.timestamps
    end
  end
end
