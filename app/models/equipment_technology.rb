class EquipmentTechnology < ApplicationRecord
  include ApplicationHelper
  acts_as :physical_object
  validates :iu_barcode, iu_barcode: true

  NESTED_ATTRIBUTES = [ :physical_object_original_identifiers_attributes ]
  FILM_GAUGES = [
    :film_gauge_8mm, :film_gauge_super_8mm, :film_gauge_9_5mm, :film_gauge_16mm, :film_gauge_super_16mm, :film_gauge_28mm,
    :film_gauge_35mm, :film_gauge_35_32mm, :film_gauge_70mm, :film_gauge_other
  ]
  FILM_GAUGES_HUMANIZED = {
    :film_gauge_8mm => "8mm", :film_gauge_super_8mm => "Super 8mm", :film_gauge_9_5mm => "9.5mm", :film_gauge_16mm => "16mm", :film_gauge_super_16mm => "Super 16mm",
    :film_gauge_28mm => "28mm", :film_gauge_35mm => "35mm", :film_gauge_35_32mm => "35/32mm", :film_gauge_70mm => "70mm", :film_gauge_other => "Other"
  }
  VIDEO_GAUGES = [
    :video_gauge_1_inch_videotape, :video_gauge_1_2_inch_videotape, :video_gauge_1_4_inch_videotape, :video_gauge_2_inch_videotape,
    :video_gauge_betacam, :video_gauge_betacam_sp, :video_gauge_betacam_sx, :video_gauge_betamax, :video_gauge_blu_ray_disc,
    :video_gauge_cartrivision, :video_gauge_d1, :video_gauge_d2, :video_gauge_d3, :video_gauge_d5, :video_gauge_d6,
    :video_gauge_d9, :video_gauge_dct, :video_gauge_digital_betacam, :video_gauge_digital8, :video_gauge_dv, :video_gauge_dvcam,
    :video_gauge_dvcpro, :video_gauge_dvd, :video_gauge_eiaj_cartridge, :video_gauge_evd_videodisc, :video_gauge_hdcam,
    :video_gauge_hi8, :video_gauge_laserdisc, :video_gauge_mii, :video_gauge_minidv, :video_gauge_hdv, :video_gauge_super_video_cd,
    :video_gauge_u_matic, :video_gauge_universal_media_disc, :video_gauge_v_cord, :video_gauge_vhs, :video_gauge_vhs_c, :video_gauge_svhs,
    :video_gauge_video8_aka_8mm_video, :video_gauge_vx, :video_gauge_videocassette, :video_gauge_open_reel_videotape,
    :video_gauge_optical_video_disc, :video_gauge_other, :video_gauge_svhs_c, :video_gauge_ced
  ]
  VIDEO_GAUGES_HUMANIZED = {
    :video_gauge_1_inch_videotape => "1 inch videotape", :video_gauge_1_2_inch_videotape => "1/2 inch videotape",
    :video_gauge_1_4_inch_videotape => "1/4 inch videotape", :video_gauge_2_inch_videotape => "2 inch videotape",
    :video_gauge_betacam => "Betacam", :video_gauge_betacam_sp => "Betacam SP", :video_gauge_betacam_sx => "Betacam SX",
    :video_gauge_betamax => "Betamax", :video_gauge_blu_ray_disc => "Blu-ray Disc", :video_gauge_cartrivision => "Cartivision",
    :video_gauge_d1 => "D1", :video_gauge_d2 => "D2", :video_gauge_d3 => "D3", :video_gauge_d5 => "D5", :video_gauge_d6 => "D6",
    :video_gauge_d9 => "D9", :video_gauge_dct => "DCT", :video_gauge_digital_betacam => "Digital Betacam", :video_gauge_digital8 => "Digital8",
    :video_gauge_dv => "DV", :video_gauge_dvcam => "DVCAM", :video_gauge_dvcpro => "DVCPRO", :video_gauge_dvd => "DVD",
    :video_gauge_eiaj_cartridge => "EIAJ Cartridge", :video_gauge_evd_videodisc => "EVD Videodisc", :video_gauge_hdcam => "HDCAM",
    :video_gauge_hi8 => "Hi8", :video_gauge_laserdisc => "LaserDisc", :video_gauge_mii => "MII", :video_gauge_minidv => "MiniDV", :video_gauge_hdv => "HDV",
    :video_gauge_super_video_cd => "Super Video CD", :video_gauge_u_matic => "U-matic", :video_gauge_universal_media_disc => "Universal Media Disc",
    :video_gauge_v_cord => "V-Cord", :video_gauge_vhs => "VHS", :video_gauge_vhs_c => "VHS-C", :video_gauge_svhs => "SVHS",
    :video_gauge_video8_aka_8mm_video => "Video8 aka 8mm video", :video_gauge_vx => "VX", :video_gauge_videocassette => "Videocassette",
    :video_gauge_open_reel_videotape => "Open reel videotape",
    :video_gauge_optical_video_disc => "Optical video disc", :video_gauge_other => "Other", :video_gauge_svhs_c => "SVHS-C", :video_gauge_ced => "CED"
  }
  RECORDED_SOUND_GAUGES = [
    :recorded_sound_gauge_open_reel_audiotape, :recorded_sound_gauge_grooved_analog_disc, :recorded_sound_gauge_1_inch_audio_tape,
    :recorded_sound_gauge_1_2_inch_audio_cassette, :recorded_sound_gauge_1_4_inch_audio_cassette, :recorded_sound_gauge_1_4_inch_audio_tape,
    :recorded_sound_gauge_2_inch_audio_tape, :recorded_sound_gauge_8_track, :recorded_sound_gauge_aluminum_disc,
    :recorded_sound_gauge_audio_cassette, :recorded_sound_gauge_audio_cd, :recorded_sound_gauge_dat, :recorded_sound_gauge_dds,
    :recorded_sound_gauge_dtrs, :recorded_sound_gauge_flexi_disc, :recorded_sound_gauge_grooved_dictabelt,
    :recorded_sound_gauge_lacquer_disc, :recorded_sound_gauge_magnetic_dictabelt, :recorded_sound_gauge_mini_cassette,
    :recorded_sound_gauge_pcm_betamax, :recorded_sound_gauge_pcm_u_matic, :recorded_sound_gauge_pcm_vhs, :recorded_sound_gauge_piano_roll,
    :recorded_sound_gauge_plastic_cylinder, :recorded_sound_gauge_shellac_disc, :recorded_sound_gauge_super_audio_cd,
    :recorded_sound_gauge_vinyl_recording, :recorded_sound_gauge_wax_cylinder, :recorded_sound_gauge_wire_recording,
    :recorded_sound_gauge_1_8_inch_audio_tape, :recorded_sound_gauge_mini_disc
  ]
  RECORDED_SOUND_GAUGES_HUMANIZED = {
    :recorded_sound_gauge_open_reel_audiotape => "Open reel audio tape",  :recorded_sound_gauge_grooved_analog_disc => "Grooved analog disc",
    :recorded_sound_gauge_1_inch_audio_tape => "1 inch audio tape",
    :recorded_sound_gauge_1_2_inch_audio_cassette => "1/2 inch audio cassette",  :recorded_sound_gauge_1_4_inch_audio_cassette => "1/4 audio cassette",
    :recorded_sound_gauge_1_4_inch_audio_tape => "1/4 inch audio tape",
    :recorded_sound_gauge_2_inch_audio_tape => "2 inch audio tape",  :recorded_sound_gauge_8_track => "8-track",
    :recorded_sound_gauge_aluminum_disc => "Aluminum disc",
    :recorded_sound_gauge_audio_cassette => "Audio cassette",  :recorded_sound_gauge_audio_cd => "Audio CD",  :recorded_sound_gauge_dat => "DAT",
    :recorded_sound_gauge_dds => "DDS", :recorded_sound_gauge_dtrs => "DTRS",  :recorded_sound_gauge_flexi_disc => "Flexi Disc",
    :recorded_sound_gauge_grooved_dictabelt => "Grooved Dictabelt", :recorded_sound_gauge_lacquer_disc => "Grooved laquer disc",
    :recorded_sound_gauge_magnetic_dictabelt => "Magnetic Dictabelt",  :recorded_sound_gauge_mini_cassette => "Mini cassette",
    :recorded_sound_gauge_pcm_betamax => "PCM Betamax",  :recorded_sound_gauge_pcm_u_matic => "PCM U-matic",
    :recorded_sound_gauge_pcm_vhs => "PCM VHS",  :recorded_sound_gauge_piano_roll => "Piano roll",
    :recorded_sound_gauge_plastic_cylinder => "Plastic cylinder",  :recorded_sound_gauge_shellac_disc => "Shellac disc",
    :recorded_sound_gauge_super_audio_cd => "Super Audio Cd",
    :recorded_sound_gauge_vinyl_recording => "Vinyl recording", :recorded_sound_gauge_wax_cylinder => "Wax cylinder",
    :recorded_sound_gauge_wire_recording => "Wire recording", :recorded_sound_gauge_1_8_inch_audio_tape => "1/8 inch audio tape",
    :recorded_sound_gauge_mini_disc => "MiniDisc"
  }
  TYPE_FIELDS = [
    :type_camera, :type_camera_accessory, :type_editor, :type_flatbed, :type_lens, :type_light, :type_reader,
    :type_photo_equipment, :type_projection_screen, :type_projector, :type_rewind, :type_shrinkage_gauge,
    :type_squawk_box, :type_splicer, :type_supplies, :type_synchronizer, :type_viewer, :type_video_deck,
    :type_other
  ]
  TYPE_FIELDS_HUMANIZED = {
    type_camera: 'Camera', type_camera_accessory: "Camera Accessory", type_editor: "Editor", type_flatbed: "Faltbed",
    type_lens: "Lens", type_light: "Light", type_reader: "Reader", type_photo_equipment: "Photo Equipment",
    type_projection_screen: "Projection Screen", type_projector: "Projector", type_rewind: "Rewind", type_shrinkage_gauge: "Shrinkage Gauge",
    type_squawk_box: "Squawk Box", type_splicer: "Splicer", type_supplies: "Supplies", type_synchronizer: "Synchronizer",
    type_viewer: "Viewer", type_video_deck: "Video Deck", type_other: "Other"
  }
  HUMANIZED_SYMBOLS = TYPE_FIELDS_HUMANIZED.merge(RECORDED_SOUND_GAUGES_HUMANIZED.merge(VIDEO_GAUGES_HUMANIZED.merge(FILM_GAUGES_HUMANIZED)))

  def initialize(args = {})
    super
    # !!!! IMPORTANT - how the nested_form gem and active-record_acts_as gem interact with form submission and params.require.permit
    # creates duplicate entries for PhysicalObjectOriginalIdentifiers, PhysicalObjectDates, Languages, RatedConditions, and
    # BooleanConditions. The above super call ends up ALSO calling the initializer for PhysicalObjects which holds the
    # actual associations for these objects. They get created correctly. However, I think that when each of these is passed
    # through self.send() below, this results in a SECOND call to creating that metadata on the underlying physical object.
    # Removing self.send impacts other metadata that is specific to the EquipmentTechnology object so cannot be removed.
    # This only appears to happen during the #create action on physical objects however
    #
    # Make sure to remove the keys for these metadata fields BEFORE iterating through them for the EquipmentTechnology attributes
    unless args.nil?
      NESTED_ATTRIBUTES.each do |na|
        args.delete(na)
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

  def gauge
    humanize_boolean_fields EquipmentTechnology::TYPE_FIELDS
  end

  def related_media_format_gauges
    case related_media_format
    when 'Film'
      humanize_boolean_fields(FILM_GAUGES)
    when 'Video'
      humanize_boolean_fields(VIDEO_GAUGES)
    when 'Recorded Sound'
      humanize_boolean_fields(RECORDED_SOUND_GAUGES)
    else
      ''
    end
  end
  def selected_related_media_format_gauges
    vals = []
    case related_media_format
    when 'Film'
      FILM_GAUGES.each do |g|
        if self[g]
          vals << g.to_s
        end
      end
    when 'Video'
      VIDEO_GAUGES.each do |g|
        if self[g]
          vals << g.to_s
        end
      end
    when 'Recorded Sound'
      RECORDED_SOUND_GAUGES.each do |g|
        if self[g]
          vals << g.to_s
        end
      end
    end
    vals
  end

  # override because Eq/Tech object are never stored in ALF - always stored in offsite location
  def storage_location
    return WorkflowStatus::IN_STORAGE_INGESTED_OFFSITE
  end

  def medium_name
    "#{medium} [#{humanize_boolean_fields EquipmentTechnology::TYPE_FIELDS}]"
  end

  def self.write_xlsx_header_row(worksheet)
    raise "No Spreadsheet header specification for EquipmentTechnology Physical Objects"
  end
  def write_xlsx_row(t, worksheet)
    raise "No Spreadsheet row specification for EquipmentTechnology Physical Objects"
  end
  def to_xml(options)
    raise "No specification for how to export EquipmentTechnology Physical Objects to XML"
  end
  def titles_text
    "N/A - Equipment/Technology"
  end

end
