class VideoParser < CsvParser
  include DateHelper
  include PhysicalObjectsHelper
  require 'csv'
  require 'manual_roll_back_error'

  VIDEO_HEADERS = [
      'Title', 'Duration', 'Series Name', 'Version', 'Format', 'Generation', 'Original Identifier', 'Base', 'Stock',
      'Picture Type', 'Capacity', 'Playback Speed', 'Alternative Title', 'Title Summary', 'Title Notes',
      'Name Authority', 'Creator', 'Publisher', 'Genre', 'Form', 'Subject', 'Series Part', 'Date', 'Location',
      'Generation Notes', 'Size', 'Aspect Ratio', 'Sound', 'Color', 'Sound Content Type', 'Dialog Language',
      'Captions or Subtitles', 'Captions or Subtitles Notes', 'Captions or Subtitles Language',
      # missing fields from sample spreadsheet but I'm adding anyway
      'Sound Format Type', 'Series Production Number', 'Sound Field', 'Noise Reduction', 'Recording Standard',
      'OCLC Number', 'Reel Number', 'Detailed Stock Information'
  ]
  # the column headers that spreadsheets should contain for Videos - they must conform to this vocabulary
  COLUMN_HEADERS = PO_HEADERS + VIDEO_HEADERS

  TITLE, DURATION, SERIES_NAME, VERSION, FORMAT, GENERATION, ORIGINAL_IDENTIFIER, BASE, STOCK = 22,23,24,25,26,27,28,29,30
  PICTURE_TYPE, CAPACITY, PLAYBACK_SPEED, ALTERNATIVE_TITLE, TITLE_SUMMARY, TITLE_NOTES = 31,32,33,34,35,36
  NAME_AUTHORITY, CREATOR, PUBLISHER, GENRE, FORM, SUBJECT, SERIES_PART, DATE, LOCATION = 37,38,39,40,41,42,43,44,45
  GENERATION_NOTES, SIZE, ASPECT_RATIO, SOUND, COLOR, SOUND_CONTENT_TYPE, DIALOG_LANGUAGE = 46,47,48,49,50,51,52
  CAPTIONS_OR_SUBTITLES, CAPTIONS_OR_SUBTITLES_NOTES, CAPTIONS_OR_SUBTITLES_LANGUAGE = 53,54,55
  SOUND_FORMAT_TYPE, SERIES_PRODUCTION_NUMBER, SOUND_CONFIGURATION, NOISE_REDUCTION, RECORDING_STANDARD = 56,57,58,59,60
  OCLC_NUMBER, REEL_NUMBER, DETAILED_STOCK_INFORMATION = 56,62,63

  # hash mapping a column header to its physical object assignment operand using send() - only plain text fields that require no validation can be set this way
  HEADERS_TO_ASSIGNER = {
      COLUMN_HEADERS[ALTERNATIVE_TITLE] => :alternative_title=,
      COLUMN_HEADERS[CAPTIONS_OR_SUBTITLES_NOTES] => :captions_or_subtitles_notes=, COLUMN_HEADERS[MISCELLANEOUS_CONDITION_TYPE] => :miscellaneous=,
      COLUMN_HEADERS[OVERALL_CONDITION_NOTES] => :condition_notes=, COLUMN_HEADERS[CONSERVATION_ACTIONS] => :conservation_actions=,
      COLUMN_HEADERS[MDPI_BARCODE] => :mdpi_barcode=, COLUMN_HEADERS[IU_BARCODE] => :iu_barcode=, COLUMN_HEADERS[FORMAT_NOTES] => :format_notes=,
      COLUMN_HEADERS[RESEARCH_VALUE_NOTES] => :research_value_notes=, COLUMN_HEADERS[ACCOMPANYING_DOCUMENTATION_LOCATION] => :accompanying_documentation_location=,
      COLUMN_HEADERS[ALF_SHELF_LOCATION] => :alf_shelf=, COLUMN_HEADERS[GENERATION_NOTES] => :generation_notes=
  }

  # special logger for parsing spreadsheets
  def self.logger
    @@logger ||= Logger.new("#{Rails.root}/log/spreadsheet_submission_logger.log")
  end
  @@mutex = Mutex.new

  def initialize(csv, spreadsheet, spreadsheet_submission)
    @csv = csv
    @spreadsheet = spreadsheet
    @spreadsheet_submission = spreadsheet_submission
    @title_cv = ControlledVocabulary.title_cv
    @title_date_cv = ControlledVocabulary.title_date_cv
    @title_date_types =  @title_date_cv[:date_type].collect{ |d| d[0] }
    @title_genre_cv = ControlledVocabulary.title_genre_cv[:genre].collect { |x| x[0] }
    @title_form_cv = ControlledVocabulary.title_form_cv[:form].collect { |x| x[0] }
  end

  def parse_csv
    parse_headers(@csv[0])
    if @parse_headers_msg.size > 0
      @spreadsheet_submission.update_attributes(failure_message: @parse_headers_msg, successful_submission: false, submission_progress: 100)
    else
      @cv = ControlledVocabulary.physical_object_cv('Video')
      @l_cv = ControlledVocabulary.language_cv
      # the error message that gets stored in the SpreadSheetSubmission if it fails parsing
      error_msg = ""
      # all physical objects created from the spreadsheet
      all_physical_objects = []
      begin
        PhysicalObject.transaction do
          # parsing spreadsheets is a two pass process. First pass makes sure that values in cells conform to the specification
          # marking each row as bad with a custom error message in the physical object if something erroneous is found. Since
          # ActiveRecord validation clears the errors map, we need to make this first pass before we attempt to save any records.
          # Only if all records pass this initial "validation" can we move on to actually attempting to persist
          # the Physical Objects in the database. We call save (instead of save!) to avoid the exception that would roll back
          # the whole transaction - so that we can process all physical objects to determine all rows that failed rather than
          # just the first row.
          @csv.each_with_index do |row, i|
            unless i == 0
              po = parse_physical_object(row, i)
              all_physical_objects << po
              if po.errors.any?
                error_msg << gen_error_msg(i, po)
              end
            end
          end

          # if @error_msg has length > 0 something blew up... otherwise we can pass off to ActiveRecord validation to see
          # passes/fails Rails validation
          if error_msg.nil? || error_msg.length == 0
            all_physical_objects.each_with_index do |po, index|
              unless po.save
                error_msg << gen_error_msg(index + 1, po)
              end
            end
          end
          if error_msg.length > 0
            raise ManualRollBackError
          else
            @spreadsheet_submission.update_attributes(successful_submission: true, submission_progress: 100)
            @spreadsheet.update_attributes(successful_upload: true)
          end
        end
      rescue Exception => error
        unless error.class == ManualRollBackError
          @em = error.message << "<br/>"
          error.backtrace.each do |line|
            @em << line << "<br/>"
          end
        end
        unless @em.blank?
          error_msg << @em.html_safe
        end
        @spreadsheet_submission.update_attributes(failure_message: error_msg, successful_submission: false, submission_progress: 100)
      end
    end
  end


  private
  def parse_headers(row)
    @headers = Hash.new
    @parse_headers_msg = ''
    # read all of the file's column headers
    row.each_with_index { |header, i|
      puts "[#{header.strip}, #{i}]"
      if @headers.keys.include?(header.strip)
        @parse_headers_msg << "The header <b>#{header.strip}</b> was duplicated at column #{i}<br/>"
      elsif header.blank?
        @parse_headers_msg << "The header is blank at column #{i}<br/>"
      else
        @headers[header.strip] = i
      end
    }

    # examine spreadsheet headers to make sure they conform to vocabulary
    @headers.keys.each do |ch|
      if !COLUMN_HEADERS.include?(ch)
        @parse_headers_msg << "><b>#{ch}</b>< is not a valid column header<br/>".html_safe
      end
    end
    # make sure that every header is present in the spreadsheet
    COLUMN_HEADERS.each do |h|
      unless @headers.keys.include?(h)
        @parse_headers_msg <<  "The column <b>#{h}</b> is missing from the spreadsheet<br/>".html_safe
      end
    end
  end


  # this method parses a single row in the spreadsheet trying to reconstitute a physical object - it creates association objects (title, series, etc) as well
  def parse_physical_object(row, i)
    puts("Parsing Physical Object at Row: #{i + 1}")
    # read all auto parse fields
    po = Video.new(spreadsheet_id: @spreadsheet.id)
    HEADERS_TO_ASSIGNER.keys.each do |k|
      po.send(HEADERS_TO_ASSIGNER[k], row[@headers[k]]) unless @headers[k].nil?
    end
    # date created
    begin
      d = Date.strptime(row[column_index DATE_CREATED], '%Y/%m/%d')
      po.date_inventoried = d
    rescue
      po.errors.add(:date, "Unable to parse date created")
    end


    # manually parse the other values to ensure conformance to controlled vocabulary
    dur = row[column_index DURATION]
    unless dur.blank?
      if po.valid_duration?(dur)
        po.send(:duration=, dur)
      else
        po.errors.add(:duration, "Improperly formatted duration value (h:mm:ss): #{dur}")
      end
    end

    tc = row[column_index CAPACITY]
    unless tc.blank?
      if po.valid_duration?(tc)
        po.send(:tape_capacity=, tc)
      else
        po.errors.add(:tape_capacity, "Improperly formatted Capacity value (h:mm:ss): #{tc}")
      end
    end

    # metadata fields common to all PO's
    parse_title_control_number(po, row)
    parse_catalog_key(po, row)
    parse_media_type(po, row)
    parse_po_location(po, row)
    parse_alf_shelf_location(po, row)
    parse_condition_rating(po, row)
    parse_research_value(po, row)
    parse_title_metadata(po, row)
    parse_unit(po, row)
    parse_user(po, row)
    parse_accompanying_documentation(po, row)
    # end common metadata fields

    gauge = row[column_index FORMAT]
    if gauge.blank?
      po.errors.add(:gauge, "Video Gauge cannot be blank!")
    elsif Video::GAUGE_VALUES.include?(gauge)
      set_value(:gauge, gauge, po)
    else
      po.errors.add(:gauge, ">#{gauge}< is not a valid Video Gauge value")
    end

    reel_number = row[column_index REEL_NUMBER]
    unless reel_number.blank?
      po.send(:reel_number=, reel_number)
    end

    detailed_stock_info = row[column_index DETAILED_STOCK_INFORMATION]
    unless detailed_stock_info.blank?
      po.send(:detailed_stock_information=, detailed_stock_info)
    end

    size = row[column_index SIZE]
    unless size.blank?
      if Video::SIZE_VALUES.include?(size)
        set_value(:size, size, po)
      else
        po.errors.add(:size, ">#{size}< is not a valid Video Size value")
      end
    end

    playback_speed = row[column_index PLAYBACK_SPEED]
    unless playback_speed.blank?
      if Video::PLAYBACK_SPEEDS.include?(playback_speed)
        set_value(:playback_speed, playback_speed, po)
      else
        po.errors.add(:playback_speed, ">#{playback_speed}< is not a valid Video Playback Speed")
      end
    end

    sound = row[column_index SOUND]
    unless sound.blank?
      if Video::SOUND_VALUES.include?(sound)
        po.send(:sound=, sound)
      else
        po.errors.add(:sound, "Invalid Sound value: #{sound}")
      end
    end

    captioned = row[column_index CAPTIONS_OR_SUBTITLES]
    po.captions_or_subtitles = true unless captioned.blank?

    # version
    version_fields = row[column_index VERSION].blank? ? [] : row[column_index VERSION].split(DELIMITER)
    version_fields.each do |vf|
      field = vf.parameterize.underscore
      if Video::VERSION_FIELDS.include?(field.to_sym)
        po.send((field << "=").to_sym, true)
      else
        # it could be 1st - 4th edition which don't 'map' easily from attribute name to humanized text
        case field
        when "1st_edition"
          po.send(:first_edition=, true)
        when "2nd_edition"
          po.send(:second_edition=, true)
        when "3rd_edition"
          po.send(:third_edition=, true)
        when "4th_edition"
          po.send(:fourth_edition=, true)
        when "original"
          po.send(:original=, true)
        else
          po.errors.add(:version, "Undefined version: #{vf}")
        end
      end
    end

    # generation
    gen_fields = row[column_index GENERATION].blank? ? [] : row[column_index GENERATION].split(DELIMITER)
    gen_fields.each do |gf|
      if Video::GENERATION_FIELDS_HUMANIZED.values.include?(gf)
        sym = Video::GENERATION_FIELDS_HUMANIZED.key(gf)
        po.send((sym.to_s << "=").to_sym, true)
      else
        po.errors.add(:generation, "Undefined generation: #{gf}")
      end
    end

    # generation_notes
    # these should be being set by HEADER_TO_ASSIGNER keys
    # gen_notes = row[column_index GENERATION_NOTES]
    # set_value(:generation_notes, gen_notes, po)

    # original identifiers
    o_ids = row[column_index ORIGINAL_IDENTIFIER].blank? ? [] : row[column_index ORIGINAL_IDENTIFIER].split(DELIMITER)
    o_ids.each do |id|
      po.physical_object_original_identifiers << PhysicalObjectOriginalIdentifier.new(identifier: id, physical_object_id: po.id)
    end

    # base
    base = row[column_index BASE]
    unless base.blank?
      if Video::BASE_FIELDS_HUMANIZED.values.include?(base)
        po.send(:base=, base)
      else
        po.errors.add(:base, "Undefined base: #{base}")
      end
    end
    # stock
    stock = row[column_index STOCK]
    unless stock.blank?
      if Video::STOCK_VALUES.include?(stock)
        po.stock = stock
      else
        po.errors.add(:stock, ">#{stock}< is not a valid Video Stock value")
      end
    end

    rs = row[column_index RECORDING_STANDARD]
    unless rs.blank?
      if Video::RECORDING_STANDARDS_VALUES.include?(rs)
        po.recording_standard = rs
      else
        po.errors.add(:recording_standard, ">#{rs}< is not a valid Video Recording Standard value")
      end
    end


    #picture type
    picture_fields = row[column_index PICTURE_TYPE].blank? ? [] : row[column_index PICTURE_TYPE].split(DELIMITER)
    picture_fields.each do |pf|
      if (Video::PICTURE_TYPE_FIELDS_HUMANIZED.values.include?(pf))
        po.send((Video::PICTURE_TYPE_FIELDS_HUMANIZED.key(pf).to_s << "=").to_sym, true)
      else
        po.errors.add(:picture_type, "Undefined picture type: #{pf}")
      end
    end

    # color
    color_fields = row[column_index COLOR].blank? ? [] : row[column_index COLOR].split(DELIMITER)
    color_fields.each do |cf|
      if Video::COLOR_FIELDS_HUMANIZED.values.include?(cf)
        po.send(Video::COLOR_FIELDS_HUMANIZED.key(cf), true)
      else
        po.errors.add(:color_fields, ">#{cf}< is not a valid Video Color value")
      end
    end

    # aspect ratio
    aspect_fields = row[column_index ASPECT_RATIO].blank? ? [] : row[column_index ASPECT_RATIO].split(DELIMITER)
    aspect_fields.each do |af|
      case af
      when "4:3"
        po.send(:image_aspect_ratio_4_3=, true)
      when "16:9"
        po.send(:image_aspect_ratio_16_9=, true)
      when "other"
        po.send(:image_aspect_ratio_other=, true)
      when "Other"
        po.send(:image_aspect_ratio_other=, true)
      else
        po.errors.add(:aspect_ratio, ">#{af}< is not a valid Video Aspect Ratio value")
      end
    end

    # sound format type
    format_fields = row[column_index SOUND_FORMAT_TYPE].blank? ? [] : row[column_index SOUND_FORMAT_TYPE].split(DELIMITER)
    format_fields.each do |ff|
      field = "sound format type #{ff}".parameterize.underscore
      if Video::SOUND_FORMAT_FIELDS.include?(field.to_sym)
        po.send((field << "=").to_sym, true)
      else
        po.errors.add(:sound_format_type, ">#{ff}< is not a valid Video Sound Format Type value")
      end
    end

    # sound content type
    content_fields = row[column_index SOUND_CONTENT_TYPE].blank? ? [] : row[column_index SOUND_CONTENT_TYPE].split(DELIMITER)
    content_fields.each do |cf|
      field = "sound content type #{cf}".parameterize.underscore
      if Video::SOUND_CONTENT_FIELDS.include?(field.to_sym)
        po.send((field << "=").to_sym, true)
      else
        po.errors.add(:sound_content_type, ">#{cf}< is not a valid Video Sound Content Type value")
      end
    end

    # sound configuration
    config_fields = row[column_index SOUND_CONFIGURATION].blank? ? [] : row[column_index SOUND_CONFIGURATION].split(DELIMITER)
    config_fields.each do |cf|
      field = "sound configuration #{cf}".parameterize.underscore
      if Video::SOUND_CONFIGURATION_FIELDS.include?(field.to_sym)
        po.send((field << "=").to_sym, true)
      else
        po.errors.add(:sound_configuration, ">#{cf}< is not a valid Video Sound Field value")
      end
    end

    # language fields both dialog and captions
    lang_fields = row[column_index DIALOG_LANGUAGE].blank? ? [] : row[column_index DIALOG_LANGUAGE].split(DELIMITER)
    langs = @l_cv[:language].collect { |x| x[0].downcase }
    lang_fields.each do |lf|
      index = langs.find_index(lf.downcase)
      if ! index.nil?
        po.languages << Language.new(language: @l_cv[:language][index][0], language_type: Language::ORIGINAL_DIALOG, physical_object_id: po.id)
      else
        po.errors.add(:dialog_language, "Undefined dialog language: #{lf}")
      end
    end
    lang_fields = row[column_index CAPTIONS_OR_SUBTITLES_LANGUAGE].blank? ? [] : row[column_index CAPTIONS_OR_SUBTITLES_LANGUAGE].split(DELIMITER)
    lang_fields.each do |lf|
      index = langs.find_index(lf.downcase)
      if !index.nil?
        po.languages << Language.new(language: @l_cv[:language][index][0], language_type: Language::CAPTIONS, physical_object_id: po.id)
      else
        po.errors.add(:caption_subtitles_language, "Undefined caption/subtitle language: '#{lf}'")
      end
    end

    # condition type fields with value ranges or booleans
    condition_fields = row[column_index CONDITION_TYPE].blank? ? [] : row[column_index CONDITION_TYPE].split(DELIMITER)
    cv = ControlledVocabulary.physical_object_cv('Video')
    val_conditions = cv[:value_condition].collect { |x| x[0].downcase }
    bool_conditions = cv[:boolean_condition].collect { |x| x[0].downcase }
    condition_fields.each do |cf|
      if bool_conditions.include?(cf.downcase)
        po.boolean_conditions << BooleanCondition.new(condition_type: cf.titleize, physical_object_id: po.id)
      else
        # some condition types have a range value (1-5), strip this off before matching against PhysicalObject::CONDITION_FIELDS
        pattern = /([a-zA-Z ]+) \(([1-4]{1})\)/
        matcher = pattern.match(cf)
        if matcher && val_conditions.include?(matcher[1].downcase)
          po.value_conditions << ValueCondition.new(condition_type: matcher[1].titleize, value: cv[:rated_condition_rating][matcher[2].to_i - 1][0], physical_object_id: po.id)
        else
          po.errors.add(:condition, "Undefined or malformed condition type: #{cf}")
        end
      end
    end
    po
  end

  def parse_title_control_number(po, row)
    # title control number
    tcn = row[column_index IUCAT_TITLE_NO]
    if !tcn.blank? && tcn.starts_with?('a')
      po.title_control_number = tcn
    elsif !tcn.blank?
      po.errors.add(:title_control_number, "Malformed IUCAT Title No: #{tcn}")
    end
  end

  def parse_catalog_key(po, row)
    ck = row[column_index CATALOG_KEY]
    if !ck.blank? && !ck.starts_with?('a')
      po.catalog_key = ck
    elsif !ck.blank?
      po.errors.add(:catalog_key, "Malformed Catalog Key: #{ck}")
    end
  end

  def parse_media_type(po, row)
    # media type is no longer used for PhysicalObjects
    #media_type = row[column_index MEDIA_TYPE]
    #if media_type.blank? || !po.media_types.include?(media_type)
    #  po.errors.add(:media_type, "Media Type blank or malformed: '#{media_type}'")
    #else
    #  po.send(:media_type=, media_type)
    medium = row[column_index MEDIUM]
    if medium.blank? || ! po.media_type_mediums.include?(medium)
      po.errors.add(:medium, "Medium: '#{medium}' is malformed or unsupported")
    else
      po.send(:medium=, medium)
    end
    #end
  end

  def parse_po_location(po, row)
    location = row[column_index CURRENT_LOCATION]
    # for now we are just storing the value in a text field, later this will be parsed
    #set_value(:location, location, po)
    #po.location = location
    if WorkflowStatus::SPREADSHEET_START_LOCATIONS.include?(location)
      ws = WorkflowStatus.build_workflow_status(location, po, true)
      po.workflow_statuses << ws
    else
      po.errors.add(:location, "Unknown or malformed Current Location field: #{location}")
    end
  end
  def parse_alf_shelf_location(po, row)
    alf_shelf = row[column_index ALF_SHELF_LOCATION]
    unless alf_shelf.blank?
      po.send(:alf_shelf=, alf_shelf)
    end
  end
  def parse_condition_rating(po, row)
    cr = row[column_index OVERALL_CONDITION]
    unless cr.blank?
      vals = @cv[:overall_condition_rating].collect { |x| x[0] }
      if vals.include?(cr)
        po.send(:condition_rating=, cr)
      else
        po.errors.add(:condition_rating, "Invalid Overall Condition Rating: #{cr}")
      end
    end
  end
  def parse_research_value(po, row)
    rv = row[column_index RESEARCH_VALUE]
    unless rv.blank?
      @cv[:research_value].collect { |x| x[0] }.each do |k|
        if k.include? (rv)
          po.send(:research_value=, k)
        end
      end
      if po.research_value.blank?
        po.errors.add(:research_value, "Invalid Research Value: #{rv}")
      end
    end
  end
  def parse_title_metadata(po, row)
    title = Title.new(title_text: row[column_index TITLE], series_part: row[column_index SERIES_PART])
    if title.title_text.blank?
      po.errors.add(:title, "Title title text cannot be blank.")
    end
    title.spreadsheet_id = @spreadsheet.id
    title_summary = row[column_index TITLE_SUMMARY]
    unless title_summary.blank?
      title.summary = title_summary
    end

    title_notes = row[column_index TITLE_NOTES]
    unless title_notes.blank?
      title.notes = title_notes
    end

    title_subject = row[column_index SUBJECT]
    unless title_subject.blank?
      title.subject = title_subject
    end
    title_name_authority = row[column_index NAME_AUTHORITY]
    unless title_name_authority.blank?
      title.name_authority = title_name_authority
    end

    dates = row[column_index DATE].to_s
    unless dates.blank?
      dates.split(DELIMITER).each do |date|
        # the HEX codes in the middle are for MS Excel which changes '-' (minus) to en dashes and/or em dashes
        date_type_rgx = /^(([\[\]0-9\/\?]+)( ?[-\xE2\x80\x94\xE2\x80\x93]{1,1} ?([\[\]0-9\/\?]+))?) ?(\(([a-zA-Z ]+)\))?/
        match = date_type_rgx.match(date)
        if match.nil?
          po.errors.add(:title_date, "Malformed date #{date}")
        else
          begin
            date_set = DateHelper.convert_dates(match[1])
            # error case - start date will always be !nil unless the string is malformed.
            # DateHelper.convert_dates will also set :start_date to nil if end_date exists but is malformed
            if date_set[:start_date].nil?
              po.errors.add(:title_date, "Malformed date #{date}")
            else
              type = (match[6].blank? ? 'TBD' : @title_date_types.include?(match[6]) ? match[6] : nil)
              if type.nil?
                po.errors.add(:title_date, "Unknown title date type: #{date}")
              else
                td = TitleDate.new(title_id: title.id, date_text: match[1], date_type: type)
                title.title_dates << td
              end
            end
          rescue => e
            po.errors.add(:title_date, "Malformed date #{date}")
          end
        end
      end
    end

    # title creators, publishers, form, genre, (subject - currently waiting on controlled vocab to implement) and location
    creator_values = row[column_index CREATOR]
    unless creator_values.blank?
      creator_values.split(DELIMITER).each do |val|
        matcher = NAME_ROLE_PATTERN.match(val)
        if matcher
          name = matcher[1]
          role = matcher[2]
          if @title_cv[:title_creator_role_type].collect { |x| x[0] }.include?(role)
            title.title_creators << TitleCreator.new(title_id: title.id, name: name, role: role)
          else
            po.errors.add(:title_creator, "Undefined Title Creator Role: #{role}")
          end
        else
          title.title_creators << TitleCreator.new(title_id: title.id, name: val, role: 'TBD')
        end
      end
    end

    publisher_values = row[column_index PUBLISHER]
    unless publisher_values.blank?
      publisher_values.split(DELIMITER).each do |pv|
        matcher = NAME_ROLE_PATTERN.match(pv)
        if matcher
          name = matcher[1]
          role = matcher[2]
          if @title_cv[:title_publisher_role_type].collect { |x| x[0] }.include?(role)
            title.title_publishers << TitlePublisher.new(title_id: title.id, name: name, publisher_type: role)
          else
            po.errors.add(:title_publisher, "Undefined Title Publisher Role: #{role}")
          end
        else
          title.title_publishers << TitlePublisher.new(title_id: title.id, name: pv, publisher_type: 'TBD')
        end
      end
    end

    form_values = row[column_index FORM]
    unless form_values.blank?
      form_values.split(DELIMITER).each do |fv|
        if @title_form_cv.include?(fv)
          title.title_forms << TitleForm.new(title_id: title.id, form: fv)
        else
          po.errors.add(:title_form, "Undefined Title Form: #{fv}")
        end
      end
    end

    genre_values = row[column_index GENRE]
    unless genre_values.blank?
      genre_values.split(DELIMITER).each do |gv|
        if @title_genre_cv.include?(gv)
          title.title_genres << TitleGenre.new(title_id: title.id, genre: gv)
        else
          po.errors.add(:title_genre, "Undefined Title Genre: #{gv}")
        end
      end
    end

    title_locs = row[column_index LOCATION]
    unless title_locs.blank?
      title_locs.split(DELIMITER).each do |tl|
        title.title_locations << TitleLocation.new(location: tl)
      end
    end

    # OCLC - new for Video
    oclc = row[column_index OCLC_NUMBER]
    unless oclc.blank?
      toi = TitleOriginalIdentifier.new(title_id: title.id, identifier: oclc, identifier_type: 'OCLC Number')
      title.title_original_identifiers << toi
    end

    # series data
    series = row[column_index SERIES_NAME].blank? ? nil : Series.new(title: row[column_index SERIES_NAME])
    unless series.nil?
      title.series = series
      series.spreadsheet_id = @spreadsheet.id
    end
    unless series.nil?
      series.save
    end
    title.save
    pot = PhysicalObjectTitle.new(physical_object_id: po.id, title_id: title.id)
    po.physical_object_titles << pot
  end


  def parse_unit(po, row)
    unit = Unit.where(abbreviation: row[column_index UNIT]).first
    if unit.nil?
      po.errors.add(:unit, "Undefined unit: #{row[column_index UNIT]}")
    else
      po.unit = unit
      # collections are tied to a unit
      collection = row[column_index COLLECTION].blank? ? nil : Collection.where(name: row[column_index COLLECTION], unit_id: unit.id).first
      # a value in the COLLECTION cell but not matching an ActiveRecord instance means we must reject the spreadsheet because all
      # collections in spreadsheet must exist prior to ingest
      if row[column_index COLLECTION] && collection.nil?
        po.errors.add(:collection, "Undefined collection for #{unit.abbreviation}: #{row[column_index COLLECTION]}")
      else
        po.collection = collection
      end
    end
  end
  def parse_user(po, row)
    email = row[column_index EMAIL_ADDRESS]
    name = row[column_index CREATED_BY]
    if !(email.blank? || name.blank?)
      username = email.split('@')[0]
      user = User.where(username: username).first
      unless user
        user = User.new(username: username, email_address: email, first_name: name.split(' ')[0], last_name: name.split(' ')[1], active: false, created_in_sheet: @spreadsheet)
        user.save
      end
      po.inventorier = user
      po.modifier = user
    elsif !(email.blank? && name.blank?)
      po.errors.add(:user, "User missing Created By or Email Address field")
    end
  end
  def parse_accompanying_documentation(po, row)
    # FIXME: this will change eventually to relational objects.
    acd = row[column_index ACCOMPANYING_DOCUMENTATION]
    unless acd.blank?
      po.send(:accompanying_documentation=, acd)
    end
  end

  def set_value(attr_symbol, val, po)
    unless val.blank?
      if @cv[attr_symbol].collect { |x| x[0] }.include? val
        po.send((attr_symbol.to_s << "=").to_sym, val)
      else
        po.errors.add(attr_symbol, "Invalid #{attr_symbol.to_s.humanize} value: #{val}")
      end
    end
  end

  def set_boolean_value(attr_symbol, val, po)
    po.send((attr_symbol.to_s << "=").to_sym, ! val.blank?)
  end

  def gen_error_msg(row, physical_object)
    msg = "<div class='po_error_div'><b>Physical Object at row #{row + 1} has the following problem(s):</b><ul>".html_safe
    physical_object.errors.keys.each do |k|
      attr = k.to_s.humanize
      problems = physical_object.errors[k].map(&:inspect).join(', ')
      msg << "<li>#{attr}: #{problems}</li>".html_safe
    end
    msg << "</ul></div>".html_safe
  end

  # feed this method a column constant (STOCK, BASE, TITLE, etc) and it returns the column index of the current spreadsheet
  # where that value resides
  def column_index(column_constant)
    @headers[COLUMN_HEADERS[column_constant]]
  end

end