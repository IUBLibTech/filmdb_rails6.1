class PhysicalObjectMetadataFields < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :date_inventoried, :datetime
    add_column :physical_objects, :user_id, :integer, limit: 8
    add_column :physical_objects, :location, :string
    add_column :physical_objects, :collection_id, :integer, limit: 8
    add_column :physical_objects, :media_type, :string
    add_column :physical_objects, :iu_barcode, :integer, limit: 8, null: false
    add_column :physical_objects, :title, :string, null: false
    add_column :physical_objects, :copy_right, :integer
    add_column :physical_objects, :format, :string
  end
end
