class Video < ApplicationRecord
  include ApplicationHelper
  acts_as :physical_object
  validates :iu_barcode, iu_barcode: true
  validates :mdpi_barcode, mdpi_barcode: true
  validates :gauge, presence: true

  # nested_form gem doesn't integrate with active_record-acts_as gem when objects are CREATED, it results in double
  # object creation from form submissions. Edits/deletes seem to work fine however. Use this in the initializer to omit
  # processing these nested attributes
  NESTED_ATTRIBUTES = [:value_conditions_attributes, :boolean_conditions_attributes, :languages_attributes,
                       :physical_object_original_identifiers_attributes, :physical_object_dates_attributes]

  GAUGE_VALUES = ControlledVocabulary.where(model_type: 'Video', model_attribute: ':gauge').pluck(:value)
  MAXIMUM_RUNTIME_VALUES = ControlledVocabulary.physical_object_cv('Video')[:maximum_runtime].collect{|r| r[0]}
  SIZE_VALUES = ControlledVocabulary.physical_object_cv('Video')[:size].collect{|r| r[0]}
  # SOUND VALUES are the same as Film
  SOUND_VALUES = ControlledVocabulary.physical_object_cv('Video')[:sound].collect{|r| r[0]}
  STOCK_VALUES = ControlledVocabulary.physical_object_cv('Video')[:stock].collect{|r| r[0]}
  RECORDING_STANDARDS_VALUES = ControlledVocabulary.physical_object_cv('Video')[:recording_standard].collect{|r| r[0]}
  PLAYBACK_SPEEDS = ControlledVocabulary.physical_object_cv('Video')[:playback_speed].collect { |r| r[0] }

  VERSION_FIELDS = [:first_edition, :second_edition, :third_edition, :fourth_edition, :abridged, :short, :long, :sample,
                    :revised, :version_original, :excerpt, :catholic, :domestic, :trailer, :english, :television, :x_rated]
  VERSION_FIELDS_HUMANIZED = {
      first_edition: "1st Edition", second_edition: "2nd Edition", third_edition: "3rd Edition",
      fourth_edition: "4th Edition", x_rated: "X-rated", version_original: 'Original'
  }
  GENERATION_FIELDS = [
      :generation_b_roll, :generation_commercial_release, :generation_copy_access, :generation_dub, :generation_duplicate,
      :generation_edited, :generation_fine_cut, :generation_intermediate, :generation_line_cut, :generation_master,
      :generation_master_production, :generation_master_distribution, :generation_off_air_recording, :generation_original,
      :generation_picture_lock, :generation_rough_cut, :generation_stock_footage, :generation_submaster, :generation_work_tapes,
      :generation_work_track, :generation_other
  ]
  GENERATION_FIELDS_HUMANIZED = {
      :generation_b_roll => "B Roll", :generation_commercial_release => "Commercial Release", :generation_copy_access => "Copy: Access",
      :generation_dub => "Dub", :generation_duplicate => "Duplicate", :generation_edited => "Edited", :generation_fine_cut => "Fine Cut",
      :generation_intermediate => "Intermediate", :generation_line_cut => "Line Cut", :generation_master => "Master",
      :generation_master_production => "Master: Production", :generation_master_distribution => "Master: Distribution",
      :generation_off_air_recording => "Off Air Recording", :generation_original => "Original",
      :generation_picture_lock => "Picture Lock", :generation_rough_cut => "Rough Cut", :generation_stock_footage => "Stock Footage",
      :generation_submaster => "Submaster", :generation_work_tapes => "Work Tapes", :generation_work_track => "Work Track",
      :generation_other => "Other"
  }

  BASE_FIELDS =[:base_acetate, :base_polyester, :base_mixed, :base_other]
  BASE_FIELDS_HUMANIZED = {
      base_acetate: "Acetate", base_polyester: "Polyester", base_mixed: "Mixed", base_other: "Other"
  }

  PICTURE_TYPE_FIELDS = [
      :picture_type_not_applicable, :picture_type_silent_picture, :picture_type_mos_picture, :picture_type_composite_picture,
      :picture_type_credits_only, :picture_type_picture_effects, :picture_type_picture_outtakes, :picture_type_other
  ]
  PICTURE_TYPE_FIELDS_HUMANIZED = {
      :picture_type_not_applicable => "Not Applicable", :picture_type_silent_picture => "Silent", :picture_type_mos_picture => "MOS", :picture_type_composite_picture => "Composite",
      :picture_type_credits_only => "Credits Only", :picture_type_picture_effects => "Picture Effects", :picture_type_picture_outtakes => "Picture Outtakes", :picture_type_other => "Other"
  }

  COLOR_FIELDS = [
      :image_color_bw, :image_color_color, :image_color_mixed, :image_color_other
  ]

  COLOR_FIELDS_HUMANIZED = {
      :image_color_bw= => "Black and White", :image_color_color= => "Color", :image_color_mixed= => "Mixed", :image_color_other= => "Other"
  }

  ASPECT_RATIO_FIELDS = [
      :image_aspect_ratio_4_3, :image_aspect_ratio_16_9, :image_aspect_ratio_other
  ]
  ASPECT_RATIO_FIELDS_HUMANIZED = {
      image_aspect_ratio_4_3: '4:3', image_aspect_ratio_16_9: '16:9', image_aspect_ratio_other: 'Other'
  }

  SOUND_FORMAT_FIELDS = [
      :sound_format_type_magnetic, :sound_format_type_digital, :sound_format_type_sound_on_separate_media, :sound_format_type_other,
  ]
  SOUND_FORMAT_FIELDS_HUMANIZED = {
      :sound_format_type_magnetic => "Magnetic", :sound_format_type_digital => "Digital", :sound_format_type_sound_on_separate_media => "Sound on Separate Media",
      :sound_format_type_other => "Other",
  }

  SOUND_CONTENT_FIELDS = [
      :sound_content_type_music_track, :sound_content_type_effects_track, :sound_content_type_dialog, :sound_content_type_composite_track,
      :sound_content_type_outtakes
  ]
  SOUND_CONTENT_FIELDS_HUMANIZED = {
      :sound_content_type_music_track => "Music Track", :sound_content_type_effects_track => "Effects Track",
      :sound_content_type_dialog => "Dialog", :sound_content_type_composite_track => "Composite", :sound_content_type_outtakes => "Outtakes",
  }

  SOUND_CONFIGURATION_FIELDS = [
      :sound_configuration_mono, :sound_configuration_stereo, :sound_configuration_surround,
      :sound_configuration_other
  ]
  SOUND_CONFIGURATION_FIELDS_HUMANIZED = {
      :sound_configuration_mono => "Mono", :sound_configuration_stereo => "Strereo", :sound_configuration_surround => "Surround",
      :sound_configuration_other => "Other"
  }
  SOUND_REDUCTION_FIELDS = [
      :sound_noise_redux_dolby_a, :sound_noise_redux_dolby_b, :sound_noise_redux_dolby_c, :sound_noise_redux_dolby_s,
      :sound_noise_redux_dolby_sr, :sound_noise_redux_dolby_nr, :sound_noise_redux_dolby_hx, :sound_noise_redux_dolby_hx_pro,
      :sound_noise_redux_dbx, :sound_noise_redux_dbx_type_1, :sound_noise_redux_dbx_type_2, :sound_noise_redux_high_com,
      :sound_noise_redux_high_com_2, :sound_noise_redux_adres, :sound_noise_redux_anrs, :sound_noise_redux_dnl,
      :sound_noise_redux_dnr, :sound_noise_redux_cedar, :sound_noise_redux_none
  ]

  SOUND_REDUCTION_FIELDS_HUMANIZED = {
      :sound_noise_redux_dolby_a => "Dolby A", :sound_noise_redux_dolby_b => "Dolby B",
      :sound_noise_redux_dolby_c => "Dolby C", :sound_noise_redux_dolby_s => "Dolby S", :sound_noise_redux_dolby_sr => "Dolby SR",
      :sound_noise_redux_dolby_nr => "Dolby NR", :sound_noise_redux_dolby_hx => "Dolby HX", :sound_noise_redux_dolby_hx_pro => "Dolby HX Pro",
      :sound_noise_redux_dbx => "DBX", :sound_noise_redux_dbx_type_1 => "DBX Type I", :sound_noise_redux_dbx_type_2 => "DBX Type II",
      :sound_noise_redux_high_com => "High Com", :sound_noise_redux_high_com_2 => "High Com II", :sound_noise_redux_adres => "andres",
      :sound_noise_redux_anrs => "ANRS", :sound_noise_redux_dnl => "DNL", :sound_noise_redux_dnr => "DNR", :sound_noise_redux_cedar => "CEDAR",
      :sound_noise_redux_none => "None"
  }


  HUMANIZED_SYMBOLS = GENERATION_FIELDS_HUMANIZED.merge(VERSION_FIELDS_HUMANIZED.merge(BASE_FIELDS_HUMANIZED.merge(
      PICTURE_TYPE_FIELDS_HUMANIZED.merge(COLOR_FIELDS_HUMANIZED.merge(
          ASPECT_RATIO_FIELDS_HUMANIZED.merge(SOUND_FORMAT_FIELDS_HUMANIZED.merge(SOUND_CONTENT_FIELDS_HUMANIZED.merge(
              SOUND_CONFIGURATION_FIELDS_HUMANIZED.merge(SOUND_REDUCTION_FIELDS_HUMANIZED)
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

    acting_as.media_type = 'Moving Image'
    # this is necessary, as is the order of the test, because when creating this type of PhysicalObject through the UI the
    # ActionController::Parameters is passed. Whereas creating this type of PhysicalObject through spreadsheet ingest creates
    # a Hash. The else statement is in case I've missed something or some other way of creating a PO is created in the
    # future that is not covered by these two.
    if args.is_a?(ActionController::Parameters) || args.is_a?(Hash)
      args.keys.each do |k|
        self.send((k.dup.to_s << "=").to_sym, args[k])
      end
    end
  end

  def medium_name
    "#{gauge} #{medium}"
  end

  # duration is input as hh:mm:ss but stored as seconds
  def tape_capacity=(time)
    if time.blank?
      super(nil)
    else
      super(time.split(':').map { |a| a.to_i }.inject(0) { |a, b| a * 60 + b})
    end
  end

  # duration is viewed as hh:mm:ss
  def tape_capacity
    unless super.nil?
      hh_mm_sec(super)
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
                       t.summary, (t.title_original_identifiers.collect {|i| "#{i.identifier} [#{i.identifier_type}]"}.join(', ') unless t.title_original_identifiers.size == 0), (t.title_publishers.collect {|pub| "#{pub.name} [#{pub.publisher_type}]"}.join(', ') unless t.title_publishers.size == 0), (t.title_creators.collect {|c| "#{c.name} [#{c.role}]"}.join(', ') unless t.title_creators.size == 0),
                       (t.title_genres.collect {|g| g.genre}.join(', ') unless t.title_genres.size == 0), (t.title_forms.collect {|f| f.form}.join(', ') unless t.title_forms.size == 0), (t.title_dates.collect {|d| "#{d.date_text} [#{d.date_type}]"}.join(', ') unless t.title_dates.size == 0),
                       (t.title_locations.collect {|l| l.location}.join(', ') unless t.title_locations.size == 0), t.notes, t.subject, t.name_authority,
                       title_control_number, catalog_key, alternative_title,
                       media_type, medium, humanize_version_fields, unit&.name, collection&.name,
                       gauge, humanize_generations_fields, generation_notes, '', '', duration, (physical_object_dates.collect {|d| "#{d.date} [#{d&.controlled_vocabulary.value}]"}.join(', ') unless physical_object_dates.size == 0),
                       humanize_base_fields, humanize_stock_fields, (physical_object_original_identifiers.collect {|oi| oi.identifier}.join(', ') unless physical_object_original_identifiers.size == 0),
                       reel_number, '', humanize_picture_type_fields, '', humanize_color_fields,
                       humanize_aspect_ratio_fields, '', sound,'', humanize_sound_format_fields,
                       humanize_sound_content_fields, humanize_sound_configuration_fields,
                       '', (languages.collect {|l| "#{l.language} [#{l.language_type}]"}.join(', ') unless languages.size == 0), format_notes,
                       accompanying_documentation, accompanying_documentation_location, condition_rating, condition_notes,
                       research_value, research_value_notes, '', '', mold,
                       ((boolean_conditions.collect {|c| "#{c.condition_type} (#{c.comment})"} + value_conditions.collect {|c| "#{c.condition_type}: #{c.value} (#{c.comment})"}).join(' | ') unless (boolean_conditions.size == 0 && value_conditions.size == 0)),
                       missing_footage, miscellaneous, conservation_actions, t.modifier&.username]
  end
end
