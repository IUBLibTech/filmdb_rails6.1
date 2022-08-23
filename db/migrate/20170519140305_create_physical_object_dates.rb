class CreatePhysicalObjectDates < ActiveRecord::Migration[4.2]
  def up
    create_table :physical_object_dates do |t|
      t.integer :physical_object_id, limit: 8
      t.integer :controlled_vocabulary_id, limit: 8
      t.string :date
      t.timestamps
    end
    remove_column :physical_objects, :edge_code
  end

  def down
    add_column :physical_objects, :edge_code, :string
    drop_table :physical_object_dates
  end
end
