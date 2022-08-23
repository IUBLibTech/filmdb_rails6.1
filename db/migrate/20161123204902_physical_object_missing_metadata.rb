class PhysicalObjectMissingMetadata < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :mdpi_barcode, :integer, limit: 8
    add_column :physical_objects, :color_bw_color, :boolean
    add_column :physical_objects, :color_bw_bw, :boolean
    add_column :physical_objects, :accompanying_documentation_location, :text
    add_column :physical_objects, :lacquer_treated, :boolean
    add_column :physical_objects, :replasticized, :boolean
    add_column :physical_objects, :spoking, :string
    add_column :physical_objects, :dusty, :boolean
    add_column :physical_objects, :rusty, :string
    add_column :physical_objects, :miscellaneous, :text
  end
end
