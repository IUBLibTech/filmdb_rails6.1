class Film < ApplicationRecord
  include ApplicationHelper
  acts_as :physical_object
  validates :iu_barcode, iu_barcode: true
  validates :mdpi_barcode, mdpi_barcode: true
  validates :gauge, presence: true
  validates :shrinkage, numericality: {allow_blank: true}

  # nested_form gem doesn't integrate with active_record-acts_as gem when objects are CREATED, it results in double
  # object creation from form submissions. Edits/deletes seem to work fine however. Use this in the initializer to omit
  # processing these nested attributes
  NESTED_ATTRIBUTES = [:value_conditions_attributes, :boolean_conditions_attributes, :languages_attributes,
                       :physical_object_original_identifiers_attributes, :physical_object_dates_attributes]

  VERSION_FIELDS = [:first_edition, :second_edition, :third_edition, :fourth_edition, :abridged, :short, :long, :sample,
                    :preview, :revised, :version_original, :captioned, :excerpt, :catholic, :domestic, :trailer, :english, :television, :x_rated]
  VERSION_FIELDS_HUMANIZED = {first_edition: "1st Edition", second_edition: "2nd Edition", third_edition: "3rd Edition", fourth_edition: "4th Edition", x_rated: "X-rated"}
  GENERATION_FIELDS = [
      :generation_negative, :generation_positive, :generation_reversal, :generation_projection_print, :generation_answer_print, :generation_work_print,
      :generation_composite, :generation_intermediate, :generation_mezzanine, :generation_kinescope, :generation_magnetic_track, :generation_optical_sound_track,
      :generation_outs_and_trims, :generation_a_roll, :generation_b_roll, :generation_c_roll, :generation_d_roll, :generation_edited,
      :generation_original_camera, :generation_original, :generation_fine_grain_master, :generation_separation_master, :generation_duplicate,
      :generation_master, :generation_other, :generation_interpositive
  ]

  GENERATION_FIELDS_HUMANIZED = {
      generation_negative: "Negative", generation_positive: "Positive", generation_reversal: "Reversal", generation_projection_print: "Projection Print",
      generation_answer_print: "Answer Print", generation_work_print: "Work Print", generation_composite: "Composite", generation_intermediate: "Intermediate",
      generation_mezzanine: "Mezzanine", generation_kinescope: "Kinescope", generation_magnetic_track: "Separate Magnetic Track", generation_optical_sound_track: "Separate Optical Track",
      generation_outs_and_trims: "Outs and Trims", generation_a_roll: "A Roll", generation_b_roll: "B Roll", generation_c_roll: "C Roll", generation_d_roll: "D Roll",
      generation_edited: "Edited", generation_original_camera: "Camera Original", generation_original: "Original",
      generation_fine_grain_master: "Fine Grain Master", generation_separation_master: "Separation Master", generation_duplicate: "Duplicate", generation_master: 'Master',
      generation_other: "Other", generation_interpositive: 'Interpositive'
  }

  BASE_FIELDS =[:base_acetate, :base_polyester, :base_nitrate, :base_mixed]
  BASE_FIELDS_HUMANIZED = {
      base_acetate: "Acetate", base_polyester: "Polyester", base_nitrate: "Nitrate", base_mixed: "Mixed"
  }

  STOCK_FIELDS = [:stock_agfa, :stock_ansco, :stock_dupont, :stock_orwo, :stock_fuji, :stock_gevaert, :stock_kodak, :stock_ferrania, :stock_3_m,:stock_agfa_gevaert, :stock_pathe, :stock_unknown]
  STOCK_FIELDS_HUMANIZED = {
      stock_agfa: 'Agfa', stock_ansco: "Ansco", stock_dupont: 'Dupont', stock_orwo: "Orwo", stock_fuji: "Fuji", stock_gevaert: "Gevaert",
      stock_kodak: "Kodak", stock_ferrania: "Ferrania", stock_3_m: '3M', stock_agfa_gevaert: 'Agfa-Gevaert', stock_pathe: 'Pathe', stock_unknown: "Unknown"
  }

  PICTURE_TYPE_FIELDS = [
      :picture_not_applicable, :picture_silent_picture, :picture_mos_picture, :picture_composite_picture, :picture_intertitles_only,
      :picture_credits_only, :picture_picture_effects, :picture_picture_outtakes, :picture_kinescope, :picture_titles, :picture_text
  ]
  PICTURE_TYPE_FIELDS_HUMANIZED = {
      picture_not_applicable: "Not Applicable", picture_silent_picture: "Silent", picture_mos_picture: "MOS",
      picture_composite_picture: "Composite", picture_intertitles_only: "Intertitles Only", picture_credits_only: "Credits Only",
      picture_picture_effects: "Picture Effects", picture_picture_outtakes: "Outtakes", picture_kinescope: "Kinescope", picture_titles: 'Titles',
      picture_text: 'Text'
  }
  COLOR_BW_FIELDS = [
      :color_bw_bw_toned, :color_bw_bw_tinted, :color_bw_bw_hand_coloring, :color_bw_bw_stencil_coloring, :color_bw_bw_black_and_white
  ]
  COLOR_COLOR_FIELDS = [
      :color_bw_color_ektachrome, :color_bw_color_kodachrome, :color_bw_color_technicolor,
      :color_bw_color_anscochrome, :color_bw_color_eco, :color_bw_color_eastman, :color_bw_color_color
  ]
  COLOR_FIELDS = COLOR_BW_FIELDS + COLOR_COLOR_FIELDS

  COLOR_FIELDS_HUMANIZED = {
      color_bw_bw_toned: "Toned (Black and White)", color_bw_bw_tinted: "Tinted (Black and White)", color_bw_color_ektachrome: "Ektachrome",
      color_bw_color_kodachrome: "Kodachrome", color_bw_color_technicolor: "Technicolor", color_bw_color_anscochrome: "Anscochrome",
      color_bw_color_eco: "Eco", color_bw_color_eastman: "Eastman", color_bw_bw: "Black and White", color_bw_bw_hand_coloring: "Hand Coloring",
      color_bw_bw_stencil_coloring: "Stencil Coloring", color_bw_color_color: "Color", color_bw_bw_black_and_white: 'Black & White'
  }

  ASPECT_RATIO_FIELDS = [
      :aspect_ratio_1_33_1, :aspect_ratio_1_37_1, :aspect_ratio_1_66_1, :aspect_ratio_1_85_1, :aspect_ratio_2_35_1, :aspect_ratio_2_39_1, :aspect_ratio_2_59_1,
      :aspect_ratio_2_66_1, :aspect_ratio_1_36, :aspect_ratio_1_18, :aspect_ratio_2_55_1
  ]
  ASPECT_RATIO_FIELDS_HUMANIZED = {
      aspect_ratio_1_33_1: "1.33:1", aspect_ratio_1_37_1: "1.37:1", aspect_ratio_1_66_1: "1.66:1", aspect_ratio_1_85_1: "1.85:1",
      aspect_ratio_2_35_1: "2.35:1", aspect_ratio_2_39_1: "2.39:1", aspect_ratio_2_59_1: "2.59:1", aspect_ratio_2_66_1: "2.66:1",
      aspect_ratio_1_36: '1.36:1', aspect_ratio_1_18: '1.18:1', aspect_ratio_2_55_1: '2.55:1'
  }

  SOUND_FORMAT_FIELDS = [
      :sound_format_optical, :sound_format_optical_variable_area, :sound_format_optical_variable_density, :sound_format_magnetic,
      :sound_format_digital_sdds, :sound_format_digital_dts, :sound_format_digital_dolby_digital,
      :sound_format_sound_on_separate_media, :sound_format_digital_dolby_digital_sr, :sound_format_digital_dolby_digital_a,
      :sound_format_optical_variable_area_bilateral,
      :sound_format_optical_variable_area_dual_bilateral, :sound_format_optical_variable_area_unilateral,
      :sound_format_optical_variable_area_dual_unilateral, :sound_format_optical_variable_area_rca_duplex,
      :sound_format_optical_variable_density_multiple_density,
  # sound content attributes
  ]
  SOUND_FORMAT_FIELDS_HUMANIZED = {
      sound_format_optical: 'Optical', sound_format_optical_variable_area: "Optical: Variable Area", sound_format_optical_variable_density: "Optical: Variable Density",
      sound_format_magnetic: "Magnetic", sound_format_digital_sdds: "Digital: SDDS", sound_format_digital_dts: "Digital: DTS", sound_format_digital_dolby_digital: "Digital: Dolby Digital",
      sound_format_sound_on_separate_media: "Sound on Separate Media", sound_format_digital_dolby_digital_sr: 'Noise Reduction: Dolby SR',
      sound_format_digital_dolby_digital_a: 'Noise Reduction: Dolby A', sound_format_optical_variable_area_bilateral: "Optical: Variable Area: Bilateral",
      sound_format_optical_variable_area_dual_bilateral: "Optical: Variable Area: Dual Bilateral",
      sound_format_optical_variable_area_unilateral: "Optical: Variable Area: Unilateral", sound_format_optical_variable_area_dual_unilateral: "Optical: Variable Area: Dual Unilateral",
      sound_format_optical_variable_area_rca_duplex: "Optical: Variable Area: RCA Duplex", sound_format_optical_variable_density_multiple_density: "Optical: Variable Density: Multiple Density",
      sound_format_optical_variable_area_maurer: "Optical: Variable Area: Multi-track (ie: Maurer)"
      # sound content attributes
  }

  SOUND_CONTENT_FIELDS = [:sound_content_music_track, :sound_content_effects_track, :sound_content_dialog, :sound_content_composite_track, :sound_content_outtakes, :sound_content_narration]
  SOUND_CONTENT_FIELDS_HUMANIZED = {
      sound_content_music_track: "Music Track", sound_content_effects_track: "Effects Track", sound_content_dialog: "Dialog",
      sound_content_composite_track: "Composite Track", sound_content_outtakes: "Outtakes", sound_content_narration: 'Narration'
  }

  SOUND_CONFIGURATION_FIELDS = [
      :sound_configuration_mono, :sound_configuration_stereo, :sound_configuration_surround, :sound_configuration_dual_mono
  ]
  SOUND_CONFIGURATION_FIELDS_HUMANIZED = {
      sound_configuration_mono: "Mono", sound_configuration_stereo: "Stereo", sound_configuration_surround: "Surround", sound_configuration_dual_mono: "Dual Mono"
  }

  CONDITION_FIELDS_HUMANIZED = { ad_strip: "AD Strip" }

  # Merge all of the humanized field maps together so the search space is singular
  HUMANIZED_SYMBOLS = GENERATION_FIELDS_HUMANIZED.merge(VERSION_FIELDS_HUMANIZED.merge(BASE_FIELDS_HUMANIZED.merge(
      STOCK_FIELDS_HUMANIZED.merge(PICTURE_TYPE_FIELDS_HUMANIZED.merge(COLOR_FIELDS_HUMANIZED.merge(
          ASPECT_RATIO_FIELDS_HUMANIZED.merge(SOUND_FORMAT_FIELDS_HUMANIZED.merge(
              SOUND_CONTENT_FIELDS_HUMANIZED.merge(SOUND_CONFIGURATION_FIELDS_HUMANIZED.merge(CONDITION_FIELDS_HUMANIZED))
          ))))))))

  def initialize(args = {})
    super
    # !!!! IMPORTANT - how the nested_form gem and active-record_acts_as gem interact with form submission and params.require.permit
    # creates duplicate entries for PhysicalObjectOriginalIdentifiers, PhysicalObjectDates, Languages, RatedConditions, and
    # BooleanConditions. The above super call ends up ALSO calling the initializer for PhysicalObjects which holds the
    # actual associations for these objects. They get created correctly. However, I think that when each of these is passed
    # through self.send() below, this results in a SECOND call to creating that metadata on the underlying physical object.
    # This only appears to happen during create action on physical objects however, make sure to remove the keys for these
    # metadata fields BEFORE iterating through them for the Film attributes
    unless args.nil?
      NESTED_ATTRIBUTES.each do |na|
        args.delete(na) unless args.nil?
      end
    end
    if args.is_a? ActionController::Parameters
      args.keys.each do |a|
        self.send(a.dup << "=", args[a])
      end
    elsif args.is_a? Hash
      args.keys.each do |k|
        self.send((k.to_s << "=").to_sym, args[k])
      end
    end
  end
  # overridden to provide for more human readable attribute names for things like :sample_rate_32k
  def self.human_attribute_name(attribute, options = {})
    self.const_get(:HUMANIZED_SYMBOLS)[attribute.to_sym] || super
  end

  def humanize_boolean_fields(field_names)
    str = ""
    field_names.each do |f|
      str << (self.specific[f] ? (str.length > 0 ? ", " << self.class.human_attribute_name(f) : self.class.human_attribute_name(f)) : "")
    end
    str
  end

  def medium_name
    "#{gauge} #{medium}"
  end

  def self.write_xlsx_header_row(worksheet)
    worksheet.add_row ["IU Barcode","MDPI Barcode", "All Title(s) on Media", "Matching Title (If more than one title on media)", "Series Title", "Series Part", "Title Country of Origin",
     "Title Summary", "Title Original Identifiers", "Title Publishers", "Title Creators",
     "Title Genres","Title Forms", "Title Dates",
     "Title Locations", "Title Notes", "Title Subject", "Title Name Authority",
     "IUCat Title Control Number","Catalog Key", "Alternative Title",
     "Media Type","Medium","Version","Unit","Collection",
     "Gauge", "Generation","Generation Notes", "Can Size", "Footage", "Duration", "Reel Dates",
     "Base", "Stock", "Original Identifiers",
     "Reel Number", "Multiple Items in Can", "Picture Type", "Frame Rate", "Color",
     "Aspect Ratio", "Anamorphic", "Sound",
     "Captions/Subtitles", "Format Type", "Content Type", "Sound Field",
     "Track Count", "Languages", "Format Notes",
     "Accompanying Documentation", "Accompanying Documentation Location", "Overall Condition", "Condition Notes",
     "Research Value", "Research Value Notes", "AD Strip", "Shrinkage", "Mold",
     "Conditions",
     "Missing Footage", "Miscellaneous", "Conservation Actions", "Title Last Modified By"
    ]
  end
  def write_xlsx_row(t, worksheet)
    worksheet.add_row [iu_barcode, mdpi_barcode, titles_text, t.title_text, t.series_title_text, t.series_part, t.country_of_origin,
      t.summary, (t.title_original_identifiers.collect {|i| "#{i.identifier} [#{i.identifier_type}]"}.join(', ') if t.title_original_identifiers.any?), (t.title_publishers.collect {|pub| "#{pub.name} [#{pub.publisher_type}]"}.join(', ') if t.title_publishers.any?), (t.title_creators.collect {|c| "#{c.name} [#{c.role}]"}.join(', ') unless t.title_creators.size == 0),
      (t.title_genres.collect {|g| g.genre}.join(', ') unless t.title_genres.size == 0), (t.title_forms.collect {|f| f.form}.join(', ') unless t.title_forms.size == 0), (t.title_dates.collect {|d| "#{d.date_text} [#{d.date_type}]"}.join(', ') unless t.title_dates.size == 0),
      (t.title_locations.collect {|l| l.location}.join(', ') unless t.title_locations.size == 0), t.notes, t.subject, t.name_authority,
      title_control_number, catalog_key, alternative_title,
      media_type, medium, humanize_version_fields, unit&.name, collection&.name,
      gauge, humanize_generations_fields, generation_notes, can_size, footage, duration, (physical_object_dates.collect {|d| "#{d.date} [#{d&.controlled_vocabulary.value}]"}.join(', ') unless physical_object_dates.size == 0),
      humanize_base_fields, humanize_stock_fields, (physical_object_original_identifiers.collect {|oi| oi.identifier}.join(', ') unless physical_object_original_identifiers.size == 0),
      reel_number, bool_to_yes_no(multiple_items_in_can), humanize_picture_type_fields, frame_rate, humanize_color_fields,
      humanize_aspect_ratio_fields, anamorphic, sound,
      bool_to_yes_no(close_caption), humanize_sound_format_fields, humanize_sound_content_fields, humanize_sound_configuration_fields,
      track_count, (languages.collect {|l| "#{l.language} [#{l.language_type}]"}.join(', ') unless languages.size == 0), format_notes,
      accompanying_documentation, accompanying_documentation_location, condition_rating, condition_notes,
      research_value, research_value_notes, ad_strip, shrinkage, mold,
      ((boolean_conditions.collect {|c| "#{c.condition_type} (#{c.comment})"} + value_conditions.collect {|c| "#{c.condition_type}: #{c.value} (#{c.comment})"}).join(' | ') unless (boolean_conditions.size == 0 && value_conditions.size == 0)),
      missing_footage, miscellaneous, conservation_actions, t.modifier&.username]
  end

  def orientation_text
    t = ""
    t << "A-wind" if orientation_a_wind
    if orientation_a_wind && orientation_b_wind
      t << " | #{'B-wind'}"
    elsif orientation_b_wind
      t << 'B-wind'
    end
    t
  end

  def to_xml(options)
    xml = options[:builder]
    xml.physicalObject do
      xml.filmdbId id
      if active_component_group.nil?
        xml.titlId titles.first.id
      else
        xml.titleId active_component_group.title.id
      end
      xml.mdpiBarcode mdpi_barcode
      xml.iucatBarcode iu_barcode
      xml.redigitize(digitized || workflow_statuses.any?{|w| w.status_name == WorkflowStatus::SHIPPED_EXTERNALLY})
      xml.iucatTitleControlNumber title_control_number
      xml.catalogKey catalog_key
      xml.format medium
      xml.unit unit.abbreviation
      xml.title titles.collect{ |t| t.title_text }.join(', ')
      xml.alternativeTitle alternative_title unless alternative_title.nil?
      xml.collectionName collection&.name
      xml.accompanyingDocumentation accompanying_documentation
      xml.accompanyingDocumentationLocation accompanying_documentation_location

      xml.gauge gauge
      xml.reelNumber reel_number
      xml.canSize can_size
      xml.footage footage
      xml.duration duration
      xml.formatNotes format_notes
      xml.frameRate frame_rate
      xml.closeCaption close_caption
      xml.sound sound
      xml.missingFootage missing_footage
      xml.conditionRating condition_rating
      xml.conditionNotes condition_notes
      xml.researchValue research_value
      xml.researchValueNotes research_value_notes
      xml.conservationActions conservation_actions
      xml.multipleItemsInCan multiple_items_in_can
      xml.miscellaneous miscellaneous
      xml.captionedOrSubtitled captioned
      xml.captionedOrSubtitleNotes captions_or_subtitles_notes
      xml.anamorphic anamorphic
      xml.trackCount track_count
      xml.returnTo storage_location
      xml.notifyAlf notify_alf

      if !active_component_group.nil?
        xml.resolution (sound_only? ? 'Audio only' : active_scan_settings.scan_resolution)
        xml.colorSpace active_scan_settings.color_space
        xml.clean active_scan_settings.clean
        xml.returnOnOriginalReel active_scan_settings.return_on_reel
      end
      xml.originalIdentifiers do
        physical_object_original_identifiers.each do |oi|
          xml.identifier oi.identifier
        end
      end
      xml.editions do
        xml.firstEdition first_edition
        xml.secondEdition second_edition
        xml.thirdEdition third_edition
        xml.fourthEdition fourth_edition
        xml.abridged abridged
        xml.short short
        xml.long long
        xml.sample sample
        xml.preview preview
        xml.revised revised
        xml.original version_original
        xml.captioned captioned
        xml.excerpt excerpt
        xml.catholic catholic
        xml.domestic domestic
        xml.english english
        xml.television television
        xml.xRated x_rated
      end
      xml.generations do
        xml.projectionPrint generation_projection_print
        xml.aRoll generation_a_roll
        xml.bRoll generation_b_roll
        xml.cRoll generation_c_roll
        xml.dRoll generation_d_roll
        xml.answerPrint generation_answer_print
        xml.composite generation_composite
        xml.duplicate generation_duplicate
        xml.edited generation_edited
        xml.fineGrainMaster generation_fine_grain_master
        xml.intermediate generation_intermediate
        xml.kinescope generation_kinescope
        xml.magneticTrack generation_magnetic_track
        xml.mezzanine generation_mezzanine
        xml.negative generation_negative
        xml.opticalSoundTrack generation_optical_sound_track
        xml.original generation_original
        xml.outsAndTrims generation_outs_and_trims
        xml.positive generation_positive
        xml.reversal generation_reversal
        xml.separationMaster generation_separation_master
        xml.workPrint generation_work_print
        xml.mixed generation_mixed
        xml.originalCamera generation_original_camera
        xml.master generation_master
        xml.other generation_other
        xml.interpositive generation_interpositive
      end
      xml.bases do
        xml.acetate base_acetate
        xml.polyester base_polyester
        xml.nitrate base_nitrate
      end
      xml.stocks do
        xml.agfa stock_agfa
        xml.ansco stock_ansco
        xml.dupont stock_dupont
        xml.orwo stock_orwo
        xml.fuji stock_fuji
        xml.gevaert stock_gevaert
        xml.kodak stock_kodak
        xml.ferrania stock_ferrania
        xml.agfa_gevaert stock_agfa_gevaert
        xml.three_m stock_3_m
        xml.pathe stock_pathe
        xml.unknown stock_unknown
      end
      xml.pictureTypes do
        xml.notApplicable picture_not_applicable
        xml.silentPicture picture_silent_picture
        xml.mosPicture picture_mos_picture
        xml.compositePicture picture_composite_picture
        xml.intertitlesOnly picture_intertitles_only
        xml.creditsOnly picture_credits_only
        xml.pictureEffects picture_picture_effects
        xml.pictureOuttakes picture_picture_outtakes
        xml.kinescope picture_kinescope
        xml.titles picture_titles
      end
      xml.dates do
        physical_object_dates.each do |pod|
          xml.date do
            xml.value pod.date
            xml.type pod.controlled_vocabulary.value
          end
        end
      end
      xml.color do
        xml.blackAndWhiteToned color_bw_bw_toned
        xml.blackAndWhiteTinted color_bw_bw_tinted
        xml.ektachrome color_bw_color_ektachrome
        xml.kodachrome color_bw_color_kodachrome
        xml.technicolor color_bw_color_technicolor
        xml.anscochrome color_bw_color_anscochrome
        xml.eco color_bw_color_eco
        xml.eastman color_bw_color_eastman
        xml.color color_bw_color_color
        xml.blackAndWhite color_bw_bw_black_and_white
        xml.handColoring color_bw_bw_hand_coloring
        xml.stencilColoring  color_bw_bw_stencil_coloring
      end
      xml.aspectRatios do
        xml.ratio_1_33_1 aspect_ratio_1_33_1
        xml.ratio_1_37_1 aspect_ratio_1_37_1
        xml.ratio_1_66_1 aspect_ratio_1_66_1
        xml.ratio_1_85_1 aspect_ratio_1_85_1
        xml.ratio_2_35_1 aspect_ratio_2_35_1
        xml.ratio_2_39_1 aspect_ratio_2_39_1
        xml.ratio_2_59_1 aspect_ratio_2_59_1
        xml.ratio_1_36_1 aspect_ratio_1_36
        xml.ratio_1_18_1 aspect_ratio_1_18
      end
      xml.soundFormats do
        xml.optical sound_format_optical
        xml.opticalVariableArea sound_format_optical_variable_area
        xml.opticalVariableDensity sound_format_optical_variable_density
        xml.magnetic sound_format_magnetic
        xml.digitalSdds sound_format_digital_sdds
        xml.digitalDts sound_format_digital_dts
        xml.dolbyDigital sound_format_digital_dolby_digital
        xml.soundOnSeparateMedia sound_format_sound_on_separate_media
        xml.digitalDolbySR sound_format_digital_dolby_digital_sr
        xml.digitalDolbyA sound_format_digital_dolby_digital_a
      end
      xml.soundContent do
        xml.musicTrack sound_content_music_track
        xml.effectsTrack sound_content_effects_track
        xml.dialog sound_content_dialog
        xml.compositeTrack sound_content_composite_track
        xml.outtakes sound_content_outtakes
        xml.narration sound_content_narration
      end
      xml.soundConfigurations do
        xml.mono sound_configuration_mono
        xml.stereo sound_configuration_stereo
        xml.surround sound_configuration_surround
        xml.dual sound_configuration_dual_mono
        xml.multiTrack sound_format_optical_variable_area_maurer
      end

      xml.languages do
        languages.each do |l|
          xml.language(l.language, type: l.language_type)
        end
      end
      xml.conditions do
        xml.mold mold
        xml.adStrip ad_strip
        value_conditions.each do |vc|
          xml.condition do
            xml.type vc.condition_type
            xml.value vc.value
            xml.comment vc.comment
          end
        end
        boolean_conditions.each do |bc|
          xml.condition do
            xml.type bc.condition_type
            xml.comment bc.comment
          end
        end
      end
    end
  end
end
