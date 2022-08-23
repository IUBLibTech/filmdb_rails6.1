class Add136And118AspectRatiosToPhysicalObjects < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :aspect_ratio_1_36, :boolean
    add_column :physical_objects, :aspect_ratio_1_18, :boolean
  end
end
