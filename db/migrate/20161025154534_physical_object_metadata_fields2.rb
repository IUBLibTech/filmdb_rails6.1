class PhysicalObjectMetadataFields2 < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :created_by, :integer, limit: 8
    add_column :physical_objects, :access, :string

    # columns for version possibilities
    add_column :physical_objects, :first_edition, :boolean
    add_column :physical_objects, :second_edition, :boolean
    add_column :physical_objects, :third_edition, :boolean
    add_column :physical_objects, :fourth_edition, :boolean
    add_column :physical_objects, :abridged, :boolean
    add_column :physical_objects, :short, :boolean
    add_column :physical_objects, :long, :boolean
    add_column :physical_objects, :sample, :boolean
    add_column :physical_objects, :preview, :boolean
    add_column :physical_objects, :revised, :boolean
    add_column :physical_objects, :version_original, :boolean
    add_column :physical_objects, :captioned, :boolean
    add_column :physical_objects, :excerpt, :boolean
    add_column :physical_objects, :color, :boolean
    add_column :physical_objects, :catholic, :boolean
    add_column :physical_objects, :domestic, :boolean
    add_column :physical_objects, :trailer, :boolean
    add_column :physical_objects, :french, :boolean
    add_column :physical_objects, :italian, :boolean
    add_column :physical_objects, :spanish, :boolean
    add_column :physical_objects, :german, :boolean
    add_column :physical_objects, :chinese, :boolean
    add_column :physical_objects, :english, :boolean
    add_column :physical_objects, :television, :boolean
    add_column :physical_objects, :x_rated, :boolean

    add_column :physical_objects, :gauge, :string

    # columns for generation
    add_column :physical_objects, :generation_projection_print, :boolean
    add_column :physical_objects, :generation_ab_a_roll, :boolean
    add_column :physical_objects, :generation_ab_b_roll, :boolean
    add_column :physical_objects, :generation_ab_c_roll, :boolean
    add_column :physical_objects, :generation_ab_d_roll, :boolean
    add_column :physical_objects, :generation_answer_print, :boolean
    add_column :physical_objects, :generation_composite, :boolean
    add_column :physical_objects, :generation_duplicate, :boolean
    add_column :physical_objects, :generation_edited, :boolean
    add_column :physical_objects, :generation_edited_camera_original, :boolean
    add_column :physical_objects, :generation_fine_grain_master, :boolean
    add_column :physical_objects, :generation_intermediate, :boolean
    add_column :physical_objects, :generation_kinescope, :boolean
    add_column :physical_objects, :generation_magnetic_track, :boolean
    add_column :physical_objects, :generation_mezzanine, :boolean
    add_column :physical_objects, :generation_negative, :boolean
    add_column :physical_objects, :generation_optical_sound_track, :boolean
    add_column :physical_objects, :generation_original, :boolean
    add_column :physical_objects, :generation_outs_and_trims, :boolean
    add_column :physical_objects, :generation_positve, :boolean
    add_column :physical_objects, :generation_reversal, :boolean
    add_column :physical_objects, :generation_separation_master, :boolean
    add_column :physical_objects, :generation_work_print, :boolean
    add_column :physical_objects, :generation_mixed, :boolean

    add_column :physical_objects, :reel_number, :string
    add_column :physical_objects, :can_size, :string
    add_column :physical_objects, :footage, :integer
    add_column :physical_objects, :duration, :string

    # values for base multiple possibilities
    add_column :physical_objects, :base_acetate, :boolean
    add_column :physical_objects, :base_polyester, :boolean
    add_column :physical_objects, :base_nitrate, :boolean
    add_column :physical_objects, :base_mixed, :boolean

    # values for stock multiple selections
    add_column :physical_objects, :stock_agfa, :boolean
    add_column :physical_objects, :stock_ansco, :boolean
    add_column :physical_objects, :stock_dupont, :boolean
    add_column :physical_objects, :stock_orwo, :boolean
    add_column :physical_objects, :stock_fuji, :boolean
    add_column :physical_objects, :stock_gevaert, :boolean
    add_column :physical_objects, :stock_kodak, :boolean
    add_column :physical_objects, :stock_ferrania, :boolean
    add_column :physical_objects, :stock_mixed, :boolean

    add_column :physical_objects, :format_notes, :text

    # picture type mutiple selections
    add_column :physical_objects, :picture_not_applicable, :boolean
    add_column :physical_objects, :picture_silent_picture, :boolean
    add_column :physical_objects, :picture_mos_picture, :boolean
    add_column :physical_objects, :picture_composite_picture, :boolean
    add_column :physical_objects, :picture_intertitles_only, :boolean
    add_column :physical_objects, :picture_credits_only, :boolean
    add_column :physical_objects, :picture_picture_effects, :boolean
    add_column :physical_objects, :picture_picture_outtakes, :boolean
    add_column :physical_objects, :picture_picture_kinescope, :boolean

    add_column :physical_objects, :frame_rate, :string

    # values for color/bw multiple selections
    add_column :physical_objects, :color_bw_bw_toned, :boolean
    add_column :physical_objects, :color_bw_bw_tinted, :boolean
    add_column :physical_objects, :color_bw_color_ektachrome, :boolean
    add_column :physical_objects, :color_bw_color_kodachrome, :boolean
    add_column :physical_objects, :color_bw_color_technicolor, :boolean
    add_column :physical_objects, :color_bw_color_anscochrome, :boolean
    add_column :physical_objects, :color_bw_color_eco, :boolean
    add_column :physical_objects, :color_bw_color_eastman, :boolean
    add_column :physical_objects, :color_bw_color_bw_mixed, :boolean

    # aspect ratio multiple selctions
    add_column :physical_objects, :aspect_ratio_1_33_1, :boolean
    add_column :physical_objects, :aspect_ratio_1_37_1, :boolean
    add_column :physical_objects, :aspect_ratio_1_66_1, :boolean
    add_column :physical_objects, :aspect_ratio_1_85_1, :boolean
    add_column :physical_objects, :aspect_ratio_2_35_1, :boolean
    add_column :physical_objects, :aspect_ratio_2_39_1, :boolean
    add_column :physical_objects, :aspect_ratio_2_59_1, :boolean

    # language multiple selection values
    add_column :physical_objects, :language_arabic, :boolean
    add_column :physical_objects, :language_chinese, :boolean
    add_column :physical_objects, :language_english, :boolean
    add_column :physical_objects, :language_french, :boolean
    add_column :physical_objects, :language_german, :boolean
    add_column :physical_objects, :language_hindi, :boolean
    add_column :physical_objects, :language_italian, :boolean
    add_column :physical_objects, :language_japanese, :boolean
    add_column :physical_objects, :language_portuguese, :boolean
    add_column :physical_objects, :language_russian, :boolean
    add_column :physical_objects, :language_spanish, :boolean

    remove_column :physical_objects, :language

    add_column :physical_objects, :close_caption, :boolean
    add_column :physical_objects, :silent, :boolean

    # sound format multiple selections
    add_column :physical_objects, :sound_format_optical_variable_area, :boolean
    add_column :physical_objects, :sound_format_optical_variable_density, :boolean
    add_column :physical_objects, :sound_format_magnetic, :boolean
    add_column :physical_objects, :sound_format_type_mixed, :boolean
    add_column :physical_objects, :sound_format_digital_sdds, :boolean
    add_column :physical_objects, :sound_format_digital_dts, :boolean
    add_column :physical_objects, :sound_format_digital_dolby_digital, :boolean
    add_column :physical_objects, :sound_format_sound_on_separate_media, :boolean

    # sound content multiple selections
    add_column :physical_objects, :sound_content_music_track, :boolean
    add_column :physical_objects, :sound_content_effects_track, :boolean
    add_column :physical_objects, :sound_content_dialog, :boolean
    add_column :physical_objects, :sound_content_composite_track, :boolean
    add_column :physical_objects, :sound_content_outtakes, :boolean

    # sound configuration multiple selections
    add_column :physical_objects, :sound_configuration_mono, :boolean
    add_column :physical_objects, :sound_configuration_stereo, :boolean
    add_column :physical_objects, :sound_configuration_surround, :boolean
    add_column :physical_objects, :sound_configuration_multi_track, :boolean
    add_column :physical_objects, :sound_configuration_dual, :boolean
    add_column :physical_objects, :sound_configuration_single, :boolean

    add_column :physical_objects, :ad_strip, :string
    add_column :physical_objects, :shrinkage, :decimal
    add_column :physical_objects, :mold, :string

    add_column :physical_objects, :color_fade, :string
    add_column :physical_objects, :perforation_damage, :string
    add_column :physical_objects, :water_damage, :string
    add_column :physical_objects, :warp, :string
    add_column :physical_objects, :brittle, :string
    add_column :physical_objects, :splice_damage, :string
    add_column :physical_objects, :dirty, :string
    add_column :physical_objects, :peeling, :string
    add_column :physical_objects, :tape_residue, :string
    add_column :physical_objects, :broken, :string
    add_column :physical_objects, :tearing, :string
    add_column :physical_objects, :loose_wind, :boolean
    add_column :physical_objects, :not_on_core_or_reel, :boolean
    add_column :physical_objects, :missing_footage, :string
    add_column :physical_objects, :scratches, :string
    add_column :physical_objects, :condition_rating, :string
    add_column :physical_objects, :condition_notes, :text
    add_column :physical_objects, :research_value, :string
    add_column :physical_objects, :research_value_notes, :text
    add_column :physical_objects, :conservation_actions, :text
  end
end
