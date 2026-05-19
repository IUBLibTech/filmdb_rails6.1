# frozen_string_literal: true

require "roo"

module SpreadsheetImports

  def self.import_both
    ActiveRecord::Base.logger = nil
    base_path = Pathname.new("/mnt/c/Users/jaalbrec/Desktop/IULMIA/")
    vids = File.join(base_path, "CeDIR Video for ingest.xlsx")
    audio = File.join(base_path, "CeDIR audio for ingest.xlsx")
    v_results = VideoImportService.new(file_path: vids, spreadsheet_id: nil).call
    debugger
    a_results = RecordedSoundImportService.new(file_path: audio, spreadsheet_id: nil).call
    debugger
  end
  class VideoImportService
    Result = Struct.new(:created, :failed, keyword_init: true)

    VIDEO_ATTR_MAP = {
      "Format" => :gauge,
      "Recording Standard" => :recording_standard,
      "Stock" => :stock,
      "Detailed Stock Information" => :detailed_stock_information,
      "Capacity" => :capacity,
      "Generation Notes" => :generation_notes,
      "Playback Speed" => :playback_speed,
      "Size" => :size,
      "Captions or Subtitles Notes" => :captions_or_subtitles_notes,
      "Reel Number" => :reel_number,
      "Base" => :base,
      "Sound" => :sound
    }.freeze

    PHYSICAL_OBJECT_ATTR_MAP = {
      "IU Barcode" => :iu_barcode,
      "MDPI Barcode" => :mdpi_barcode,
      "Current Location" => :location,
      "ALF Shelf Location" => :alf_shelf,
      "Overall Condition" => :condition_rating,
      "Overall Condition Notes" => :condition_notes,
      "Research Value" => :research_value,
      "Research Value Notes" => :research_value_notes,
      "Format Notes" => :format_notes,
      "Conservation Actions" => :conservation_actions,
      "Miscellaneous Condition Type" => :miscellaneous,
      "Duration" => :duration,
      "Medium" => :medium
    }.freeze

    SIZE_FRACTIONS = {
      "1/2" => "½",
      "1/3" => "⅓",
      "2/3" => "⅔",
      "1/4" => "¼",
      "3/4" => "¾",
      "1/5" => "⅕",
      "2/5" => "⅖",
      "3/5" => "⅗",
      "4/5" => "⅘",
      "1/6" => "⅙",
      "5/6" => "⅚",
      "1/7" => "⅐",
      "1/8" => "⅛",
      "3/8" => "⅜",
      "5/8" => "⅝",
      "7/8" => "⅞",
      "1/9" => "⅑",
      "1/10" => "⅒"
    }.freeze

    def initialize(file_path:, spreadsheet_id: nil)
      @file_path = file_path
      @spreadsheet_id = spreadsheet_id
    end

    def call
      workbook = Roo::Spreadsheet.open(file_path)
      sheet = workbook.sheet(0)

      raw_headers = sheet.row(1)
      headers = raw_headers.map { |h| normalize_header(h) }
      header_index = build_header_index(headers)
      created = []
      failed = []

      data_row_numbers = (2..sheet.last_row).to_a
      total_rows = data_row_numbers.size

      data_row_numbers.each_with_index do |row_number, idx|
        @row_values = sheet.row(row_number)

        puts "processing row #{idx + 1} of #{total_rows}"

        next if @row_values.all? { |v| v.blank? }

        begin
          ActiveRecord::Base.transaction do
            @user = import_user!
            User.current_username = @user.username
            @title_text = value_for(@row_values, header_index, "Title")
            @title = create_title!(@title_text, @user)
            create_title_date!(@title, value_for(@row_values, header_index, "Date"))

            @video = Video.new
            @physical_object = physical_object_for(@video)

            assign_physical_object_attributes!(@physical_object, @row_values, header_index, @user)
            assign_title_to_physical_object!(@physical_object, @title)

            timestamp = Time.current
            assign_physical_object_timestamps!(@physical_object, timestamp)

            ws1 = WorkflowStatus.build_workflow_status(WorkflowStatusesHelper::JUST_INVENTORIED_WELLS, @physical_object, true)
            ws2 = WorkflowStatus.build_workflow_status(WorkflowStatusesHelper::IN_STORAGE_AWAITING_INGEST, @physical_object, true)
            @physical_object.workflow_statuses << ws1
            ws1.save!
            @physical_object.workflow_statuses << ws2
            ws2.save!
            @physical_object.current_workflow_status = ws2
            @physical_object.save!

            @video = @physical_object.actable
            raise "Expected physical_object.actable to be a Video, got #{@video.class.name}" unless @video.is_a?(Video)

            assign_video_attributes!(@video, @row_values, header_index)
            @video.save!

            create_original_identifier!(@physical_object, value_for(@row_values, header_index, "Original Identifier"))
            create_previous_barcodes!(@physical_object, value_for(@row_values, header_index, "Previous barcode"))

            created << @video
          end
        rescue => e
          failed << {
            row: row_number,
            error: e.message,
            data: @row_values,
            physical_object: @physical_object,
            title: @title,
            video: @video,
            backtrace: e.backtrace
          }
        end
      end

      Result.new(created: created, failed: failed)
    end

    private

    attr_reader :file_path, :spreadsheet_id

    def build_header_index(headers)
      headers.each_with_index.to_h
    end

    def normalize_header(header)
      header.to_s
            .unicode_normalize(:nfkc)
            .gsub(/\u00A0/, " ")
            .gsub(/\s+/, " ")
            .strip
    end

    def value_for(row_values, header_index, wanted_header)
      index = header_index[normalize_header(wanted_header)]
      return nil if index.nil?

      row_values[index]
    end

    def physical_object_for(video)
      if video.respond_to?(:build_physical_object)
        video.build_physical_object
      elsif video.respond_to?(:physical_object) && video.physical_object.present?
        video.physical_object
      else
        raise "Video does not expose a physical_object association. Adjust physical_object_for to match your acts_as setup."
      end
    end

    def assign_physical_object_timestamps!(physical_object, timestamp)
      physical_object[:created_at] = timestamp if physical_object.has_attribute?(:created_at)
      physical_object[:updated_at] = timestamp if physical_object.has_attribute?(:updated_at)
      physical_object[:date_inventoried] = timestamp if physical_object.has_attribute?(:date_inventoried)
    end

    def import_user!
      @import_user ||= begin
                         user = User.find_by(username: "filmdb")
                         raise "Could not find User with username 'filmdb'" unless user

                         user
                       end
    end

    def assign_physical_object_attributes!(physical_object, row_values, header_index, user)
      physical_object.inventorier = user
      physical_object.modifier = user
      physical_object.unit_id = lookup_unit_id(value_for(row_values, header_index, "Unit"))
      physical_object.collection_id = lookup_collection_id
      physical_object.spreadsheet_id = spreadsheet_id if spreadsheet_id.present?

      raw_iu_barcode = value_for(row_values, header_index, "IU Barcode")
      physical_object.iu_barcode = cast_value(:iu_barcode, raw_iu_barcode) if raw_iu_barcode.present?

      raw_mdpi_barcode = value_for(row_values, header_index, "MDPI Barcode")
      physical_object.mdpi_barcode = cast_value(:mdpi_barcode, raw_mdpi_barcode) if raw_mdpi_barcode.present?

      assign_mapped_attributes(physical_object, row_values, header_index, PHYSICAL_OBJECT_ATTR_MAP)
    end

    def assign_title_to_physical_object!(physical_object, title)
      physical_object.physical_object_titles.build(title: title)
    end

    def assign_video_attributes!(video, row_values, header_index)
      assign_mapped_attributes(video, row_values, header_index, VIDEO_ATTR_MAP)
      assign_video_flags!(video, row_values, header_index)
    end

    def assign_mapped_attributes(record, row_values, header_index, map)
      map.each do |header, attribute|
        value = value_for(row_values, header_index, header)
        next if value.blank?

        record.public_send("#{attribute}=", cast_value(attribute, value))
      end
    end

    def cast_value(attribute, value)
      case attribute
      when :iu_barcode, :mdpi_barcode, :duration
        value.to_s.strip.presence&.to_i
      when :size
        normalize_size(value)
      when :captions_or_subtitles
        truthy?(value)
      else
        value.to_s.strip.presence
      end
    end

    def normalize_size(value)
      text = value.to_s.strip
      return nil if text.blank?

      text = text.tr("x", "×")
      text = text.gsub(/\s*×\s*/i, " × ")

      SIZE_FRACTIONS.each do |ascii, unicode|
        text = text.gsub(/(\d+)\s+#{Regexp.escape(ascii)}/, "\\1#{unicode}")
        text = text.gsub(/\b#{Regexp.escape(ascii)}\b/, unicode)
      end

      text.squeeze(" ").strip
    end

    def truthy?(value)
      case value.to_s.strip.downcase
      when "yes", "y", "true", "1", "t" then true
      else false
      end
    end

    def create_title!(title_text, creator_user)
      raise "Missing Title value" if title_text.blank?

      title = Title.new(title_text: title_text.to_s.strip)
      assign_title_creator!(title, creator_user)
      title.save!
      title
    end

    def assign_title_creator!(title, creator_user)
      title.creator = creator_user
      title.modifier = creator_user
    end

    def create_title_date!(title, date_text)
      return if date_text.blank? || date_text.to_s.downcase == "unknown"

      title_date = TitleDate.new(
        title_id: title.id,
        date_text: date_text.to_s.strip,
        date_type: "TBD"
      )

      title_date.save!
      title_date
    end

    def create_original_identifier!(physical_object, identifier_text)
      return if identifier_text.blank?

      pooi = PhysicalObjectOriginalIdentifier.new(
        identifier: identifier_text.to_s.strip
      )
      pooi.physical_object = physical_object
      pooi.save!
      pooi
    end

    def create_previous_barcodes!(physical_object, value)
      split_values(value).each do |barcode|
        next if barcode.blank?

        PhysicalObjectOldBarcode.create!(
          physical_object: physical_object,
          iu_barcode: barcode.to_s.strip.to_i
        )
      end
    end

    def lookup_unit_id(unit_abbreviation)
      abbreviation = unit_abbreviation.to_s.strip
      return nil if abbreviation.blank?

      unit = Unit.find_by(abbreviation: abbreviation)
      raise "Could not find Unit with abbreviation #{abbreviation.inspect}" unless unit

      unit.id
    end

    def lookup_collection_id
      collection = Collection.find_by(name: "Center for Disability and Referral")
      raise "Could not find Collection named 'Center for Disability and Referral'" unless collection

      collection.id
    end

    def split_values(value)
      value.to_s
           .split(/[,;|\n]+/)
           .map(&:strip)
           .reject(&:blank?)
    end

    def assign_video_flags!(video, row_values, header_index)
      apply_single_choice_flag(video, value_for(row_values, header_index, "Color"), {
        "B/W" => :image_color_bw,
        "Black and White" => :image_color_bw,
        "Color" => :image_color_color,
        "Mixed" => :image_color_mixed,
        "Other" => :image_color_other
      })

      apply_single_choice_flag(video, value_for(row_values, header_index, "Aspect Ratio"), {
        "4:3" => :image_aspect_ratio_4_3,
        "16:9" => :image_aspect_ratio_16_9,
        "5:4" => :image_aspect_ratio_5_4,
        "16:10" => :image_aspect_ratio_16_10,
        "21:9" => :image_aspect_ratio_21_9
      })

      apply_single_choice_flag(video, value_for(row_values, header_index, "Captions or Subtitles"), {
        "Yes" => :captions_or_subtitles,
        "No" => nil
      })

      apply_single_choice_flag(video, value_for(row_values, header_index, "Sound Format Type"), {
        "Magnetic" => :sound_format_type_magnetic,
        "Digital" => :sound_format_type_digital,
        "Sound on separate media" => :sound_format_type_sound_on_separate_media,
        "Other" => :sound_format_type_other
      })

      apply_single_choice_flag(video, value_for(row_values, header_index, "Sound Content Type"), {
        "Music track" => :sound_content_type_music_track,
        "Effects track" => :sound_content_type_effects_track,
        "Dialog" => :sound_content_type_dialog,
        "Composite track" => :sound_content_type_composite_track,
        "Outtakes" => :sound_content_type_outtakes
      })

      apply_single_choice_flag(video, value_for(row_values, header_index, "Sound Field"), {
        "Mono" => :sound_configuration_mono,
        "Stereo" => :sound_configuration_stereo,
        "Surround" => :sound_configuration_surround
      })

      apply_single_choice_flag(video, value_for(row_values, header_index, "Noise Reduction"), {
        "Dolby A" => :sound_noise_redux_dolby_a,
        "Dolby B" => :sound_noise_redux_dolby_b,
        "Dolby C" => :sound_noise_redux_dolby_c,
        "Dolby S" => :sound_noise_redux_dolby_s,
        "Dolby SR" => :sound_noise_redux_dolby_sr,
        "Dolby NR" => :sound_noise_redux_dolby_nr,
        "Dolby HX" => :sound_noise_redux_dolby_hx,
        "Dolby HX Pro" => :sound_noise_redux_dolby_hx_pro,
        "dbx" => :sound_noise_redux_dbx,
        "dbx Type 1" => :sound_noise_redux_dbx_type_1,
        "dbx Type 2" => :sound_noise_redux_dbx_type_2,
        "High Com" => :sound_noise_redux_high_com,
        "High Com 2" => :sound_noise_redux_high_com_2,
        "ADRES" => :sound_noise_redux_adres,
        "ANRS" => :sound_noise_redux_anrs,
        "DNL" => :sound_noise_redux_dnl,
        "DNR" => :sound_noise_redux_dnr,
        "CEDAR" => :sound_noise_redux_cedar,
        "None" => :sound_noise_redux_none
      })

      assign_list_flags(video, value_for(row_values, header_index, "Picture Type"), {
        "Not applicable" => :picture_type_not_applicable,
        "Silent picture" => :picture_type_silent_picture,
        "MOS picture" => :picture_type_mos_picture,
        "Composite picture" => :picture_type_composite_picture,
        "Credits only" => :picture_type_credits_only,
        "Picture effects" => :picture_type_picture_effects,
        "Picture outtakes" => :picture_type_picture_outtakes,
        "Other" => :picture_type_other
      })
    end

    def apply_single_choice_flag(record, value, mapping)
      selected_attribute = mapping[value.to_s.strip]

      mapping.values.compact.each do |attr|
        record.public_send("#{attr}=", false)
      end

      record.public_send("#{selected_attribute}=", true) if selected_attribute
    end

    def assign_list_flags(record, value, mapping)
      selected_values = split_values(value)

      mapping.each do |token, attribute|
        record.public_send("#{attribute}=", selected_values.include?(token))
      end
    end
  end

  class RecordedSoundImportService
    Result = Struct.new(:created, :failed, keyword_init: true)

    RECORDED_SOUND_ATTR_MAP = {
      "Format" => :gauge,
      "Part" => :part,
      "Size" => :size,
      "Base" => :base,
      "Stock" => :stock,
      "Detailed Stock Information" => :detailed_stock_information,
      "Playback" => :playback,
      "Generation Notes" => :generation_notes,
      "Track Configuration" => :track_configuration,
      "Capacity" => :capacity,
      "Noise Reduction" => :noise_reduction,
      "Multiple Items In Can" => :multiple_items_in_can
    }.freeze

    PHYSICAL_OBJECT_ATTR_MAP = {
      "IU Barcode" => :iu_barcode,
      "MDPI Barcode" => :mdpi_barcode,
      "Current Location" => :location,
      "ALF Shelf Location" => :alf_shelf,
      "Overall Condition" => :condition_rating,
      "Overall Condition Notes" => :condition_notes,
      "Research Value" => :research_value,
      "Research Value Notes" => :research_value_notes,
      "Format Notes" => :format_notes,
      "Conservation Actions" => :conservation_actions,
      "Miscellaneous Condition Type" => :miscellaneous,
      "Duration" => :duration,
      "Medium" => :medium
    }.freeze

    def initialize(file_path:, spreadsheet_id: nil)
      @file_path = file_path
      @spreadsheet_id = spreadsheet_id
    end

    def call
      workbook = Roo::Spreadsheet.open(file_path)
      sheet = workbook.sheet(0)

      raw_headers = sheet.row(1)
      headers = raw_headers.map { |h| normalize_header(h) }
      header_index = build_header_index(headers)

      created = []
      failed = []

      data_row_numbers = (2..sheet.last_row).to_a
      total_rows = data_row_numbers.size

      data_row_numbers.each_with_index do |row_number, idx|
        @row_values = sheet.row(row_number)

        puts "processing row #{idx + 1} of #{total_rows}"

        next if @row_values.all? { |v| v.blank? }

        begin
          ActiveRecord::Base.transaction do
            @user = import_user!
            User.current_username = @user.username

            @title_text = value_for(@row_values, header_index, "Title")
            @title_summary = value_for(@row_values, header_index, "Title Summary")
            @date_text = value_for(@row_values, header_index, "Date")

            @title = create_title!(@title_text, @title_summary, @user)
            create_title_date!(@title, @date_text)

            @recorded_sound = RecordedSound.new
            @physical_object = physical_object_for(@recorded_sound)

            assign_physical_object_attributes!(@physical_object, @row_values, header_index, @user)
            assign_title_to_physical_object!(@physical_object, @title)

            timestamp = Time.current
            assign_physical_object_timestamps!(@physical_object, timestamp)

            ws1 = WorkflowStatus.build_workflow_status(WorkflowStatusesHelper::JUST_INVENTORIED_WELLS, @physical_object, true)
            ws2 = WorkflowStatus.build_workflow_status(WorkflowStatusesHelper::IN_STORAGE_AWAITING_INGEST, @physical_object, true)
            @physical_object.workflow_statuses << ws1
            ws1.save!
            @physical_object.workflow_statuses << ws2
            ws2.save!
            @physical_object.current_workflow_status = ws2
            @physical_object.save!

            @recorded_sound = @physical_object.actable
            raise "Expected physical_object.actable to be a RecordedSound, got #{@recorded_sound.class.name}" unless @recorded_sound.is_a?(RecordedSound)

            assign_recorded_sound_attributes!(@recorded_sound, @row_values, header_index)
            @recorded_sound.save!

            create_original_identifier!(@physical_object, value_for(@row_values, header_index, "Original Identifier"))

            created << @recorded_sound
          end
        rescue => e
          failed << {
            row: row_number,
            error: e.message,
            data: @row_values,
            physical_object: @physical_object,
            title: @title,
            recorded_sound: @recorded_sound,
            backtrace: e.backtrace
          }
        end
      end

      Result.new(created: created, failed: failed)
    end

    private

    attr_reader :file_path, :spreadsheet_id

    def build_header_index(headers)
      headers.each_with_index.to_h
    end

    def normalize_header(header)
      header.to_s
            .unicode_normalize(:nfkc)
            .gsub(/\u00A0/, " ")
            .gsub(/\s+/, " ")
            .strip
    end

    def value_for(row_values, header_index, wanted_header)
      index = header_index[normalize_header(wanted_header)]
      return nil if index.nil?

      row_values[index]
    end

    def physical_object_for(recorded_sound)
      if recorded_sound.respond_to?(:build_physical_object)
        recorded_sound.build_physical_object
      elsif recorded_sound.respond_to?(:physical_object) && recorded_sound.physical_object.present?
        recorded_sound.physical_object
      else
        raise "RecordedSound does not expose a physical_object association. Adjust physical_object_for to match your acts_as setup."
      end
    end

    def assign_physical_object_timestamps!(physical_object, timestamp)
      physical_object[:created_at] = timestamp
      physical_object[:updated_at] = timestamp
      physical_object[:date_inventoried] = timestamp
    end

    def import_user!
      @import_user ||= begin
                         user = User.find_by(username: "filmdb")
                         raise "Could not find User with username 'filmdb'" unless user

                         user
                       end
    end

    def assign_physical_object_attributes!(physical_object, row_values, header_index, user)
      physical_object.inventorier = user
      physical_object.modifier = user
      physical_object.unit_id = lookup_unit_id(value_for(row_values, header_index, "Unit"))
      physical_object.collection_id = lookup_collection_id
      physical_object.spreadsheet_id = spreadsheet_id if spreadsheet_id.present?

      raw_iu_barcode = value_for(row_values, header_index, "IU Barcode")
      physical_object.iu_barcode = cast_value(:iu_barcode, raw_iu_barcode) if raw_iu_barcode.present?

      raw_mdpi_barcode = value_for(row_values, header_index, "MDPI Barcode")
      physical_object.mdpi_barcode = cast_value(:mdpi_barcode, raw_mdpi_barcode) if raw_mdpi_barcode.present?

      assign_mapped_attributes(physical_object, row_values, header_index, PHYSICAL_OBJECT_ATTR_MAP)
    end

    def assign_title_to_physical_object!(physical_object, title)
      physical_object.physical_object_titles.build(title: title)
    end

    def assign_recorded_sound_attributes!(recorded_sound, row_values, header_index)
      assign_mapped_attributes(recorded_sound, row_values, header_index, RECORDED_SOUND_ATTR_MAP)
      #assign_recorded_sound_flags!(recorded_sound, row_values, header_index)
    end

    def assign_mapped_attributes(record, row_values, header_index, map)
      map.each do |header, attribute|
        value = value_for(row_values, header_index, header)
        next if value.blank?

        record.public_send("#{attribute}=", cast_value(attribute, value))
      end
    end

    def cast_value(attribute, value)
      case attribute
      when :iu_barcode, :mdpi_barcode, :duration
        value.to_s.strip.presence&.to_i
      when :multiple_items_in_can
        truthy?(value)
      else
        value.to_s.strip.presence
      end
    end

    def truthy?(value)
      case value.to_s.strip.downcase
      when "yes", "y", "true", "1", "t" then true
      else false
      end
    end

    def create_title!(title_text, title_summary, creator_user)
      raise "Missing Title value" if title_text.blank?

      title = Title.new(title_text: title_text.to_s.strip)
      title.summary = title_summary.to_s.strip if title_summary.present?
      title.creator = creator_user
      title.modifier = creator_user
      title.save!
      title
    end

    def create_title_date!(title, date_text)
      return if date_text.blank?

      title_date = TitleDate.new(
        title_id: title.id,
        date_text: date_text.to_s.strip,
        date_type: "TBD"
      )

      title_date.save!
      title_date
    end

    def create_original_identifier!(physical_object, identifier_text)
      return if identifier_text.blank?

      pooi = PhysicalObjectOriginalIdentifier.new(
        identifier: identifier_text.to_s.strip
      )
      pooi.physical_object = physical_object
      pooi.save!
      pooi
    end

    def lookup_unit_id(unit_abbreviation)
      abbreviation = unit_abbreviation.to_s.strip
      return nil if abbreviation.blank?

      unit = Unit.find_by(abbreviation: abbreviation)
      raise "Could not find Unit with abbreviation #{abbreviation.inspect}" unless unit

      unit.id
    end

    def lookup_collection_id
      collection = Collection.find_by(name: "Center for Disability and Referral")
      raise "Could not find Collection named 'Center for Disability and Referral'" unless collection

      collection.id
    end

    def assign_recorded_sound_flags!(recorded_sound, row_values, header_index)
      assign_single_choice_flag(recorded_sound, value_for(row_values, header_index, "Sound Content Type"), {
        "Music track" => :sound_content_type_music_track,
        "Effects track" => :sound_content_type_effects_track,
        "Dialog" => :sound_content_type_dialog,
        "Composite track" => :sound_content_type_composite_track,
        "Outtakes" => :sound_content_type_outtakes
      })

      assign_single_choice_flag(recorded_sound, value_for(row_values, header_index, "Sound Field"), {
        "Dual mono" => :sound_configuration_dual_mono,
        "Mono" => :sound_configuration_mono,
        "Stereo" => :sound_configuration_stereo,
        "Surround" => :sound_configuration_surround,
        "Unknown" => :sound_configuration_unknown,
        "Other" => :sound_configuration_other
      })

      assign_single_choice_flag(recorded_sound, value_for(row_values, header_index, "Noise Reduction"), {
        "Dolby A" => :sound_noise_redux_dolby_a,
        "Dolby B" => :sound_noise_redux_dolby_b,
        "Dolby C" => :sound_noise_redux_dolby_c,
        "Dolby S" => :sound_noise_redux_dolby_s,
        "Dolby SR" => :sound_noise_redux_dolby_sr,
        "Dolby NR" => :sound_noise_redux_dolby_nr,
        "Dolby HX" => :sound_noise_redux_dolby_hx,
        "Dolby HX Pro" => :sound_noise_redux_dolby_hx_pro,
        "dbx" => :sound_noise_redux_dbx,
        "dbx Type 1" => :sound_noise_redux_dbx_type_1,
        "dbx Type 2" => :sound_noise_redux_dbx_type_2,
        "High Com" => :sound_noise_redux_high_com,
        "High Com 2" => :sound_noise_redux_high_com_2,
        "ADRES" => :sound_noise_redux_adres,
        "ANRS" => :sound_noise_redux_anrs,
        "DNL" => :sound_noise_redux_dnl,
        "DNR" => :sound_noise_redux_dnr,
        "CEDAR" => :sound_noise_redux_cedar,
        "None" => :sound_noise_redux_none
      })
    end

    def assign_single_choice_flag(record, value, mapping)
      selected_attribute = mapping[value.to_s.strip]

      mapping.values.compact.each do |attr|
        record.public_send("#{attr}=", false)
      end

      record.public_send("#{selected_attribute}=", true) if selected_attribute
    end
  end

end