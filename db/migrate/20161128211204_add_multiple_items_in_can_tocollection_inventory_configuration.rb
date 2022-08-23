class AddMultipleItemsInCanTocollectionInventoryConfiguration < ActiveRecord::Migration[4.2]
  def change
    add_column :collection_inventory_configurations, :multiple_items_in_can, :boolean
  end
end
