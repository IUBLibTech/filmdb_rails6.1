class AddAspectRatiosToVideo < ActiveRecord::Migration[6.1]
  def change
    add_column :videos, :image_aspect_ratio_5_4, :boolean
    add_column :videos, :image_aspect_ratio_16_10, :boolean
    add_column :videos, :image_aspect_ratio_21_9, :boolean
  end
end
