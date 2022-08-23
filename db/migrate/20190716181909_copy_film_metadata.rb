class CopyFilmMetadata < ActiveRecord::Migration[4.2]
  ATTRS = [
      :first_edition, :second_edition, :third_edition, :fourth_edition, :abridged, :short, :long, :sample, :preview,
      :revised, :version_original, :captioned, :excerpt, :catholic, :domestic, :trailer, :english, :television, :x_rated,
      :gauge, :generation_projection_print, :generation_a_roll, :generation_b_roll, :generation_c_roll, :generation_d_roll,
      :generation_answer_print, :generation_composite, :generation_duplicate, :generation_edited, :generation_fine_grain_master,
      :generation_intermediate, :generation_kinescope, :generation_magnetic_track, :generation_mezzanine, :generation_negative,
      :generation_optical_sound_track, :generation_original, :generation_outs_and_trims, :generation_positive,
      :generation_reversal, :generation_separation_master, :generation_work_print, :generation_mixed, :reel_number,
      :can_size, :footage, :base_acetate, :base_polyester, :base_nitrate, :base_mixed, :stock_agfa, :stock_ansco,
      :stock_dupont, :stock_orwo, :stock_fuji, :stock_gevaert, :stock_kodak, :stock_ferrania,
      :picture_not_applicable, :picture_silent_picture, :picture_mos_picture, :picture_composite_picture,
      :picture_intertitles_only, :picture_credits_only, :picture_picture_effects, :picture_picture_outtakes,
      :picture_kinescope, :frame_rate, :color_bw_bw_toned, :color_bw_bw_tinted, :color_bw_color_ektachrome,
      :color_bw_color_kodachrome, :color_bw_color_technicolor, :color_bw_color_anscochrome, :color_bw_color_eco,
      :color_bw_color_eastman, :aspect_ratio_1_33_1, :aspect_ratio_1_37_1, :aspect_ratio_1_66_1, :aspect_ratio_1_85_1,
      :aspect_ratio_2_35_1, :aspect_ratio_2_39_1, :aspect_ratio_2_59_1, :sound, :sound_format_optical_variable_area,
      :sound_format_optical_variable_density, :sound_format_magnetic, :sound_format_digital_sdds,
      :sound_format_digital_dts, :sound_format_digital_dolby_digital, :sound_format_sound_on_separate_media,
      :sound_content_music_track, :sound_content_effects_track, :sound_content_dialog, :sound_content_composite_track,
      :sound_content_outtakes, :sound_configuration_mono, :sound_configuration_stereo, :sound_configuration_surround,
      :sound_configuration_multi_track, :sound_configuration_dual_mono, :ad_strip, :shrinkage, :mold, :missing_footage,
      :multiple_items_in_can, :color_bw_color_color, :color_bw_bw_black_and_white,
      :color_bw_bw_hand_coloring, :color_bw_bw_stencil_coloring, :captions_or_subtitles_notes, :sound_format_optical,
      :anamorphic, :track_count, :generation_original_camera, :generation_master, :sound_format_digital_dolby_digital_sr,
      :sound_format_digital_dolby_digital_a, :stock_3_m, :stock_agfa_gevaert, :stock_pathe, :stock_unknown, :aspect_ratio_2_66_1,
      :aspect_ratio_1_36, :aspect_ratio_1_18, :picture_titles, :generation_other, :sound_content_narration, :close_caption,
      :generation_notes]
  def change
    # the migration is tricky in that when the acts_as relation is setup between Film/Video and PhysicalObejct, you cannot create the
    # actable for existing PhysicalObjects without also modifying the created_at attribute of PhysicalObject (which is VERY problematic).
    # So this check ensures that the acting_as relationship is DISABLED (commented out in the Film model)
    if Film.is_a? PhysicalObject || PhysicalObject.method_defined?(:actable)
      raise "Cannot migrate PhysicalObjects into Films while the acts_as relation is active - comment out 'actable' in PhysicalObject and 'acts_as' in Film. "+
                "Also comment out iu and MDPI barcode validation in Film"
    else
      PhysicalObject.transaction do
        pos = PhysicalObject.all
        pos.each_with_index do |po, i|
          puts "Processing #{i+1} of #{pos.size}"
          film = Film.new
          ATTRS.each do |attr|
            film[attr] = po[attr]
          end
          film.save!
          po.actable_id = film.id
          po.actable_type = 'Film'
          po.save!
        end
      end
    end
  end
end
