class ChangePhysicalObjectDurationToInteger < ActiveRecord::Migration[4.2]
  def up
    change_column :physical_objects, :duration, :integer, default:nil


    # from the physical objects table
    remove_column :physical_objects, :french
    remove_column :physical_objects, :german
    remove_column :physical_objects, :italian
    remove_column :physical_objects, :spanish
    remove_column :physical_objects, :chinese
    remove_column :physical_objects, :color
    remove_column :physical_objects, :black_and_white
    remove_column :physical_objects, :summary
    remove_column :physical_objects, :distributors
    remove_column :physical_objects, :credits

    # from the collection inventory configuration table
    remove_column :collection_inventory_configurations, :summary
    remove_column :collection_inventory_configurations, :distributors
    remove_column :collection_inventory_configurations, :credits
  end

  def down
    change_column :physical_objects, :duration, :text

    add_column :physical_objects, :french, :boolean
    add_column :physical_objects, :german, :boolean
    add_column :physical_objects, :italian, :boolean
    add_column :physical_objects, :spanish, :boolean
    add_column :physical_objects, :chinese, :boolean
    add_column :physical_objects, :color, :boolean
    add_column :physical_objects, :black_and_white, :boolean
    add_column :physical_objects, :summary, :text
    add_column :physical_objects, :distributors, :text
    add_column :physical_objects, :credits, :text

    add_column :collection_inventory_configurations, :summary, :boolean
    add_column :collection_inventory_configurations, :distributors, :boolean
    add_column :collection_inventory_configurations, :credits, :boolean

  end
end
