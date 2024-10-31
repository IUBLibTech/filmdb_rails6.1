class RecordedSound < ApplicationRecord
  include ApplicationHelper
  acts_as :physical_object
  validates :iu_barcode, iu_barcode: true
  validates :mdpi_barcode, mdpi_barcode: true
  validates :gauge, presence: true

  NESTED_ATTRIBUTES = [:value_conditions_attributes, :boolean_conditions_attributes, :languages_attributes,
                       :physical_object_original_identifiers_attributes, :physical_object_dates_attributes]
  GAUGE_VALUES = ControlledVocabulary.where(model_type: 'RecordedSound', model_attribute: ':gauge').pluck(:value)
  SIZE_VALUES = ControlledVocabulary.physical_object_cv('RecordedSound')[:size].collect{|r| r[0]}
  STOCK_VALUES = ControlledVocabulary.physical_object_cv('RecordedSound')[:stock].collect{|r| r[0]}
  PLAYBACK_SPEEDS = ControlledVocabulary.physical_object_cv('RecordedSound')[:playback_speed].collect { |r| r[0] }

  VERSION_FIELDS = [:version_first_edition, :version_second_edition, :version_third_edition, :version_fourth_edition,
                    :version_abridged,  :version_anniversary, :version_domestic, :version_english, :version_excerpt, :version_long,
                    :version_original, :version_reissue, :version_revised, :version_sample, :version_short,
                    :version_x_rated]
  VERSION_FIELDS_HUMANIZED = {
      version_first_edition: "1st Edition", second_edition: "2nd Edition", third_edition: "3rd Edition", fourth_edition: "4th Edition",
      version_abridged: 'Abridged', version_anniversary: 'Anniversary', version_domestic: 'Domestic', version_english: 'English',
      version_excerpt:"Excerpt", version_long: "Long", version_original: "Original", version_reissue: "Reissue",
      version_revised: "Revised", version_sample: "Sample", version_short: "Short", x_rated: "X-rated"
  }
  GENERATION_FIELDS = [:generation_copy_access, :generation_dub, :generation_duplicate, :generation_intermediate,
                       :generation_master, :generation_master_distribution, :generation_master_production,
                       :generation_off_air_recording, :generation_original_recording, :generation_preservation,
                       :generation_work_tapes, :generation_other]
  GENERATION_FIELDS_HUMANIZED = {
      :generation_copy_access => "Copy: Access", :generation_dub => "Dub", :generation_duplicate => "Duplicate",
      :generation_intermediate => "Intermediate", :generation_master => "Master",
      :generation_master_distribution => "Master: Distribution", :generation_master_production => "Master: Production",
      :generation_off_air_recording => "Off Air Recording", :generation_original_recording => "Original Recording",
      :generation_preservation => "Preservation", :generation_work_tapes => "Work Tapes", :generation_other => "Other"
  }

  # Is this necessary? base is a text field for RecordedSound objects but Video is the same and has this declaration
  BASE_FIELDS =[:base_acetate, :base_aluminum, :base_cardboard, :base_glass, :base_plaster, :base_polyester,
                :base_shellac, :base_steel, :base_vinyl, :base_wax]
  BASE_FIELDS_HUMANIZED = {
      base_acetate: "Acetate", base_aluminum: "Aluminum", base_cardboard: "Cardboard", base_glass: "Glass",
      base_plaster: "Plaster", base_polyester: "Polyester", base_shellac: "Shellac", base_steel: "Steel",
      base_vinyl: "Vinyl", base_wax: "Wax"
  }

  SOUND_CONTENT_FIELDS = [:sound_content_type_composite_track, :sound_content_type_dialog, :sound_content_type_effects_track,
                           :sound_content_type_music_track, :sound_content_type_outtakes]
  SOUND_CONTENT_FIELDS_HUMANIZED = {
      :sound_content_type_composite_track => "Composite track", :sound_content_type_dialog => "Dialog", :sound_content_type_effects_track => "Effects track",
      :sound_content_type_music_track => "Music track", :sound_content_type_outtakes => "Outtakes"
  }

  SOUND_CONFIGURATION_FIELDS = [:sound_configuration_dual_mono, :sound_configuration_mono, :sound_configuration_stereo,
                                :sound_configuration_surround, :sound_configuration_unknown, :sound_configuration_other]
  SOUND_CONFIGURATION_FIELDS_HUMANIZED = {
      :sound_configuration_dual_mono => "Dual Mono", :sound_configuration_mono => "Mono", :sound_configuration_stereo => "Stereo",
      :sound_configuration_surround => "Surround", :sound_configuration_unknown => "Unknown", :sound_configuration_other => "Other"
  }

  HUMANIZED_SYMBOLS = GENERATION_FIELDS_HUMANIZED.merge(VERSION_FIELDS_HUMANIZED.merge(BASE_FIELDS_HUMANIZED.merge(
      SOUND_CONTENT_FIELDS_HUMANIZED.merge(SOUND_CONFIGURATION_FIELDS_HUMANIZED))))


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
        args.delete(na)
      end
    end

    acting_as.media_type = 'Recorded Sound'

    # this is necessary, as is the order of the test, because when creating this type of PhysicalObject through the UI the
    # ActionController::Parameters is passed. Whereas creating this type of PhysicalObject through spreadsheet ingest creates
    # a Hash. The else statement is in case I've missed something or some other way of creating a PO is created in the
    # future that is not covered by these two.
    if args.is_a?(ActionController::Parameters) || args.is_a?(Hash)
      args.keys.each do |k|
        self.send((k.dup.to_s << "=").to_sym, args[k])
      end
    elsif args.is_a? Hash
      args.keys.each do |k|
        self.send((k.to_s << "=").to_sym, args[k])
      end
    end
  end

  def medium_name
    "#{gauge}"
  end

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
    worksheet.add_row ["IU Barcode","MDPI Barcode", "All Title(s) on Media", "Matching Title (If more than one title on media)",
                       "Series Title", "Series Part", "Title Country of Origin",
                       "Title Summary", "Title Original Identifiers", "Title Publishers", "Title Creators",
                       "Title Genres","Title Forms", "Title Dates",
                       "Title Locations", "Title Notes", "Title Subject", "Title Name Authority",
                       "IUCat Title Control Number","Catalog Key", "Alternative Title",
                       "Medium","Version","Unit","Collection",
                       "Format", "Generation","Generation Notes","Duration", "Sides", "Part", "Dates",
                       "Base", "Stock", "Detailed Stock Information" "Original Identifiers",
                       "Multiple Items in Can", "Playback",
                       "Format Type", "Content Type", "Sound Field",
                       "Languages", "Format Notes",
                       "Accompanying Documentation", "Accompanying Documentation Location", "Overall Condition", "Condition Notes",
                       "Research Value", "Research Value Notes",
                       "Conditions",
                       "Miscellaneous", "Conservation Actions", "Title Last Modified By"
                      ]
  end
  def write_xlsx_row(t, worksheet)
    worksheet.add_row [iu_barcode, mdpi_barcode, titles_text, t.title_text,
                       t.series_title_text, t.series_part, t.country_of_origin,
                       t.summary, (t.title_original_identifiers.collect {|i| "#{i.identifier} [#{i.identifier_type}]"}.join(', ') if t.title_original_identifiers.any?),
                       (t.title_publishers.collect {|pub| "#{pub.name} [#{pub.publisher_type}]"}.join(', ') if t.title_publishers.any?),
                       (t.title_creators.collect {|c| "#{c.name} [#{c.role}]"}.join(', ') if t.title_creators.any?),
                       (t.title_genres.collect {|g| g.genre}.join(', ') if t.title_genres.any?),
                       (t.title_forms.collect {|f| f.form}.join(', ') if t.title_forms.any?),
                       (t.title_dates.collect {|d| "#{d.date_text} [#{d.date_type}]"}.join(', ') if t.title_dates.any?),
                       (t.title_locations.collect {|l| l.location}.join(', ') if t.title_locations.any?),
                       t.notes, t.subject, t.name_authority,
                       title_control_number, catalog_key, alternative_title,
                       medium, humanize_version_fields, unit&.name, collection&.name,
                       gauge, humanize_generations_fields, generation_notes, duration, sides, part,
                       (physical_object_dates.collect {|d| "#{d.date} [#{d&.controlled_vocabulary.value}]"}.join(', ') if physical_object_dates.any?),
                       humanize_base_fields, humanize_stock_fields, detailed_stock_information,
                       (physical_object_original_identifiers.collect {|oi| oi.identifier}.join(', ') if physical_object_original_identifiers.any?),
                       bool_to_yes_no(multiple_items_in_can), playback,
                       humanize_sound_format_fields, humanize_sound_content_fields, humanize_sound_configuration_fields,
                       (languages.collect {|l| "#{l.language} [#{l.language_type}]"}.join(', ') unless languages.size == 0), format_notes,
                       accompanying_documentations, accompanying_documentation_location, condition_rating, condition_notes,
                       research_value, research_value_notes,
                       ((boolean_conditions.collect {|c| "#{c.condition_type} (#{c.comment})"} + value_conditions.collect {|c| "#{c.condition_type}: #{c.value} (#{c.comment})"}).join(' | ') unless (boolean_conditions.size == 0 && value_conditions.size == 0)),
                       miscellaneous, conservation_actions, t.modifier&.username]
  end
end
