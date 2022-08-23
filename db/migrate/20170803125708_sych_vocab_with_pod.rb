class SychVocabWithPod < ActiveRecord::Migration[4.2]
  def change
    remove_column :physical_objects, :sound_format_mixed
    remove_column :physical_objects, :stock_mixed
    add_column :physical_objects, :sound_format_digital_dolby_digital_sr, :boolean
    add_column :physical_objects, :sound_format_digital_dolby_digital_a, :boolean
    add_column :physical_objects, :stock_3_m, :boolean
    add_column :physical_objects, :stock_agfa_gevaert, :boolean
    add_column :physical_objects, :stock_pathe, :boolean
    add_column :physical_objects, :stock_unknown, :boolean
    add_column :physical_objects, :aspect_ratio_2_66_1, :boolean

    add_column :component_groups, :hand_clean_only, :boolean, default: false
    add_column :component_groups, :return_on_original_reel, :boolean
    add_column :component_groups, :hd, :boolean
  end
end
