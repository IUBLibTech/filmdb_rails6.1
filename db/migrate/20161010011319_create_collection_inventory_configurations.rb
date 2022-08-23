class CreateCollectionInventoryConfigurations < ActiveRecord::Migration[4.2]
  def change
    create_table :collection_inventory_configurations do |t|
      t.integer :collection_id, limit: 8
      t.boolean :location
      t.boolean :copy_right
      t.boolean :series_name
      t.boolean :series_production_number
      t.boolean :series_part
      t.boolean :alternative_title
      t.boolean :title_version
      t.boolean :item_original_identifier
      t.boolean :summary
      t.boolean :creator
      t.boolean :distributors
      t.boolean :credits
      t.boolean :language
      t.boolean :accompanying_documentation
      t.boolean :notes

      t.timestamps
    end
  end
end
