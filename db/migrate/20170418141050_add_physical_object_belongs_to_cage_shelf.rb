class AddPhysicalObjectBelongsToCageShelf < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :cage_shelf_id, :integer, limit: 8, null: true
  end
end
