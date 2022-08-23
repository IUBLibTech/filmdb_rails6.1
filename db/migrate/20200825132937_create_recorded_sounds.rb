class CreateRecordedSounds < ActiveRecord::Migration[4.2]
  def change
    create_table :recorded_sounds do |t|
      t.boolean :version_first_edition
      t.boolean :version_second_edition
      t.boolean :version_third_edition
      t.boolean :version_fourth_edition
      t.boolean :version_abridged
      t.boolean :version_anniversary
      t.boolean :version_domestic
      t.boolean :version_english
      t.boolean :version_excerpt
      t.boolean :version_long
      t.boolean :version_original
      t.boolean :version_reissue
      t.boolean :version_revised
      t.boolean :version_sample
      t.boolean :version_short
      t.boolean :version_x_rated

      t.string :gauge
      t.boolean :generation_copy_access
      t.boolean :generation_dub
      t.boolean :generation_duplicate
      t.boolean :generation_intermediate
      t.boolean :generation_master
      t.boolean :generation_master_distribution
      t.boolean :generation_master_production
      t.boolean :generation_off_air_recording
      t.boolean :generation_original_recording
      t.boolean :generation_preservation
      t.boolean :generation_work_tapes
      t.boolean :generation_other

      t.string :sides
      t.string :part
      t.string :size
      t.string :base
      t.string :stock
      t.text :detailed_stock_information
      t.boolean :multiple_items_in_can
      t.string :playback

      t.boolean :sound_content_type_composite_track
      t.boolean :sound_content_type_dialog
      t.boolean :sound_content_type_effects_track
      t.boolean :sound_content_type_music_track
      t.boolean :sound_content_type_outtakes

      t.boolean :sound_configuration_dual_mono
      t.boolean :sound_configuration_mono
      t.boolean :sound_configuration_stereo
      t.boolean :sound_configuration_surround
      t.boolean :sound_configuration_unknown
      t.boolean :sound_configuration_other

      t.string :mold

      # so it can also be a PhysicalObject
      t.integer  :actable_id
      t.string   :actable_type

      t.timestamps
    end
  end
end
