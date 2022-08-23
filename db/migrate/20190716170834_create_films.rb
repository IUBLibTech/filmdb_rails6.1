class CreateFilms < ActiveRecord::Migration[4.2]
  def change

    # need to remove local tested acts-as stuff, shouldn't be necessary in dev/test/prod instances but does no harm
    remove_column :physical_objects, :actable_id if column_exists?(:physical_objects, :actable_id)
    remove_column :physical_objects, :actable_type if column_exists?(:physical_objects, :actable_type)
    change_table :physical_objects do |t|
      t.integer :actable_id
      t.string :actable_type
    end

    if table_exists? :films
      drop_table :films
    end

    create_table :films do |t|
      t.boolean :first_edition
      t.boolean :second_edition
      t.boolean :third_edition
      t.boolean :fourth_edition
      t.boolean :abridged
      t.boolean :short
      t.boolean :long
      t.boolean :sample
      t.boolean :preview
      t.boolean :revised
      t.boolean :version_original
      t.boolean :captioned
      t.boolean :excerpt
      t.boolean :catholic
      t.boolean :domestic
      t.boolean :trailer
      t.boolean :english
      t.boolean :television
      t.boolean :x_rated
      t.string :gauge
      t.boolean :generation_projection_print
      t.boolean :generation_a_roll
      t.boolean :generation_b_roll
      t.boolean :generation_c_roll
      t.boolean :generation_d_roll
      t.boolean :generation_answer_print
      t.boolean :generation_composite
      t.boolean :generation_duplicate
      t.boolean :generation_edited
      t.boolean :generation_fine_grain_master
      t.boolean :generation_intermediate
      t.boolean :generation_kinescope
      t.boolean :generation_magnetic_track
      t.boolean :generation_mezzanine
      t.boolean :generation_negative
      t.boolean :generation_optical_sound_track
      t.boolean :generation_original
      t.boolean :generation_outs_and_trims
      t.boolean :generation_positive
      t.boolean :generation_reversal
      t.boolean :generation_separation_master
      t.boolean :generation_work_print
      t.boolean :generation_mixed
      t.string :reel_number
      t.string :can_size
      t.integer :footage
      t.boolean :base_acetate
      t.boolean :base_polyester
      t.boolean :base_nitrate
      t.boolean :base_mixed
      t.boolean :stock_agfa
      t.boolean :stock_ansco
      t.boolean :stock_dupont
      t.boolean :stock_orwo
      t.boolean :stock_fuji
      t.boolean :stock_gevaert
      t.boolean :stock_kodak
      t.boolean :stock_ferrania
      t.boolean :picture_not_applicable
      t.boolean :picture_silent_picture
      t.boolean :picture_mos_picture
      t.boolean :picture_composite_picture
      t.boolean :picture_intertitles_only
      t.boolean :picture_credits_only
      t.boolean :picture_picture_effects
      t.boolean :picture_picture_outtakes
      t.boolean :picture_kinescope
      t.string :frame_rate
      t.boolean :color_bw_bw_toned
      t.boolean :color_bw_bw_tinted
      t.boolean :color_bw_color_ektachrome
      t.boolean :color_bw_color_kodachrome
      t.boolean :color_bw_color_technicolor
      t.boolean :color_bw_color_anscochrome
      t.boolean :color_bw_color_eco
      t.boolean :color_bw_color_eastman
      t.boolean :aspect_ratio_1_33_1
      t.boolean :aspect_ratio_1_37_1
      t.boolean :aspect_ratio_1_66_1
      t.boolean :aspect_ratio_1_85_1
      t.boolean :aspect_ratio_2_35_1
      t.boolean :aspect_ratio_2_39_1
      t.boolean :aspect_ratio_2_59_1
      t.text :sound
      t.boolean :sound_format_optical_variable_area
      t.boolean :sound_format_optical_variable_density
      t.boolean :sound_format_magnetic
      t.boolean :sound_format_digital_sdds
      t.boolean :sound_format_digital_dts
      t.boolean :sound_format_digital_dolby_digital
      t.boolean :sound_format_sound_on_separate_media
      t.boolean :sound_content_music_track
      t.boolean :sound_content_effects_track
      t.boolean :sound_content_dialog
      t.boolean :sound_content_composite_track
      t.boolean :sound_content_outtakes
      t.boolean :sound_configuration_mono
      t.boolean :sound_configuration_stereo
      t.boolean :sound_configuration_surround
      t.boolean :sound_configuration_multi_track
      t.boolean :sound_configuration_dual_mono
      t.string :ad_strip
      t.decimal :shrinkage
      t.string :mold
      t.text :missing_footage
      t.boolean :multiple_items_in_can
      t.boolean :color_bw_color_color
      t.boolean :color_bw_bw_black_and_white
      t.boolean :color_bw_bw_hand_coloring
      t.boolean :color_bw_bw_stencil_coloring
      t.text :captions_or_subtitles_notes
      t.boolean :sound_format_optical
      t.string :anamorphic
      t.integer :track_count
      t.boolean :generation_original_camera
      t.boolean :generation_master
      t.boolean :sound_format_digital_dolby_digital_sr
      t.boolean :sound_format_digital_dolby_digital_a
      t.boolean :stock_3_m
      t.boolean :stock_agfa_gevaert
      t.boolean :stock_pathe
      t.boolean :stock_unknown
      t.boolean :aspect_ratio_2_66_1
      t.boolean :aspect_ratio_1_36
      t.boolean :aspect_ratio_1_18
      t.boolean :picture_titles
      t.boolean :generation_other
      t.boolean :sound_content_narration
      t.string :close_caption
      t.text :generation_notes
    end
  end
end
