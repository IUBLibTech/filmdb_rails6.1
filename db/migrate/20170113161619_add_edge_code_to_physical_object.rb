class AddEdgeCodeToPhysicalObject < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :edge_code, :text
  end
end
