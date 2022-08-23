class PhysicalObjectAdditionalMetadataFields < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :series_name, :string
    add_column :physical_objects, :series_production_number, :string
    add_column :physical_objects, :series_part, :string
    add_column :physical_objects, :alternative_title, :string
    add_column :physical_objects, :title_version, :string
    add_column :physical_objects, :item_original_identifier, :string
    add_column :physical_objects, :summary, :text
    add_column :physical_objects, :creator, :string
    add_column :physical_objects, :distributors, :string
    add_column :physical_objects, :credits, :string
    add_column :physical_objects, :language, :string
    add_column :physical_objects, :accompanying_documentation, :text
    add_column :physical_objects, :notes, :text

  end
end
