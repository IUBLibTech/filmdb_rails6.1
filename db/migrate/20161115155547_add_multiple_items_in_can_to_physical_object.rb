class AddMultipleItemsInCanToPhysicalObject < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :multiple_items_in_can, :boolean
  end
end
