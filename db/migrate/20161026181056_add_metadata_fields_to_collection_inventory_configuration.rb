class AddMetadataFieldsToCollectionInventoryConfiguration < ActiveRecord::Migration[4.2]
  def change
    add_column :collection_inventory_configurations, :generation, :boolean
    add_column :collection_inventory_configurations, :base, :boolean
    add_column :collection_inventory_configurations, :stock, :boolean
    add_column :collection_inventory_configurations, :access, :boolean
    add_column :collection_inventory_configurations, :gauge, :boolean
    add_column :collection_inventory_configurations, :can_size, :boolean
    add_column :collection_inventory_configurations, :footage, :boolean
    add_column :collection_inventory_configurations, :duration, :boolean
    add_column :collection_inventory_configurations, :reel_number, :boolean
    add_column :collection_inventory_configurations, :format_notes, :boolean
    add_column :collection_inventory_configurations, :picture_type, :boolean
    add_column :collection_inventory_configurations, :frame_rate, :boolean
    add_column :collection_inventory_configurations, :color_or_bw, :boolean
    add_column :collection_inventory_configurations, :aspect_ratio, :boolean
    add_column :collection_inventory_configurations, :sound_field_language, :boolean
    add_column :collection_inventory_configurations, :captions_or_subtitles, :boolean
    add_column :collection_inventory_configurations, :silent, :boolean
    add_column :collection_inventory_configurations, :sound_format_type, :boolean
    add_column :collection_inventory_configurations, :sound_content_type, :boolean
    add_column :collection_inventory_configurations, :sound_configuration, :boolean
    add_column :collection_inventory_configurations, :ad_strip, :boolean
    add_column :collection_inventory_configurations, :shrinkage, :boolean
    add_column :collection_inventory_configurations, :mold, :boolean
    add_column :collection_inventory_configurations, :condition_type, :boolean
    add_column :collection_inventory_configurations, :condition_rating, :boolean
    add_column :collection_inventory_configurations, :research_value, :boolean
    add_column :collection_inventory_configurations, :conservation_actions, :boolean
  end
end
