class CreatePhysicalObjectOriginalIdentifiers < ActiveRecord::Migration[4.2]
  def up
    create_table :physical_object_original_identifiers do |t|
      t.integer :physical_object_id, limit: 8
      t.string :identifier, null: false
      t.timestamps
    end
    PhysicalObject.all.each do |p|
      PhysicalObjectOriginalIdentifier.new(physical_object_id: p.id, identifier: p.item_original_identifier).save unless p.item_original_identifier.blank?
    end
    remove_column :physical_objects, :item_original_identifier
  end
  def down
    drop_table :physical_object_original_identifiers
    add_column :physical_objects, :item_original_identifier, :string
  end
end
