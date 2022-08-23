class DropCollectionInventoryConfiguration < ActiveRecord::Migration[4.2]
  def change
    drop_table :collection_inventory_configurations
  end
end
