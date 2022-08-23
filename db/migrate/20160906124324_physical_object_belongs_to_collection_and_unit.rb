class PhysicalObjectBelongsToCollectionAndUnit < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :unit_id, :integer, limit: 8
  end
end
