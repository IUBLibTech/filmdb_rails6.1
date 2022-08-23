class CreatePhysicalObjectTitles < ActiveRecord::Migration[4.2]
  def up
    create_table :physical_object_titles do |t|
      t.integer :title_id, limit: 8
      t.integer :physical_object_id, limit: 8
      t.timestamps
    end
    remove_column :physical_objects, :title_id
  end

  def down
    drop_table :physical_object_titles
    add_column :physical_objects, :title_id, :integer, limit: 8
  end
end
