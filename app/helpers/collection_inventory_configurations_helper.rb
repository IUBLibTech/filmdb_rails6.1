module CollectionInventoryConfigurationsHelper

  def self.default_config
    CollectionInventoryConfiguration.new(
        alternative_title: true, series_part: true, item_original_identifier: true,
        creator:true, location: true, title_version: true, gauge: true,
        generation: true, color_or_bw: true, silent: true, reel_number: true, can_size: true, format_notes: true,
        accompanying_documentation: true, ad_strip: true, mold: true, condition_type: true, condition_rating: true,
        multiple_items_in_can: true
    )
  end
end
