class RecordedSoundParser < CsvParser
  include DateHelper
  include PhysicalObjectsHelper
  require 'csv'
  require 'manual_roll_back_error'

  RECORDED_SOUND_HEADERS = [
      'Title', 'Alternative Title', 'Title Notes', 'Title Summary', 'Series Name', 'Series Part', 'Creator', 'Publisher',
      'Name Authority', 'Genre', 'Form', 'Subject', 'Date', 'Location', 'Version', 'Original Identifier', 'Gauge',
      'Stock', 'Detailed Stock Information', 'Capacity', 'Generation', 'Generation Notes', 'Sides', 'Part',
      'Duration', 'Playback Speed', 'Size', 'Sound Configuration', 'Sound Content Type', 'Language', 'Base',
      'Mold','Noise Reduction'
  ]
  # the column headers that spreadsheets should contain for Recorded Sound - they must conform to this vocabulary
  COLUMN_HEADERS = PO_HEADERS + RECORDED_SOUND_HEADERS

  TITLE, ALTERNATIVE_TITLE, TITLE_NOTES, TITLE_SUMMARY, SERIES_NAME, SERIES_PART, CREATOR, PUBLISHER = 22,23,24,25,26,27,28,29
  NAME_AUTHORITY, GENRE, FORM, SUBJECT, DATE, LOCATION, VERSION, ORIGINAL_IDENTIFIER, GAUGE = 30,31,32,33,34,35,36,37,38
  STOCK, DETAILED_STOCK_INFORMATION, CAPACITY, GENERATION, GENERATION_NOTES, SIDES, PART = 39,40,41,42,43,44,45
  DURATION, PLAYBACK_SPEED, SIZE, SOUND_CONFIGURATION, SOUND_CONTENT_TYPE, LANGUAGE, BASE = 46,47,48,49,50,51,52
  MOLD, NOISE_REDUCTION = 53,54

  # hash mapping a column header to its physical object assignment operand using send() - only plain text fields that require no validation can be set this way
  HEADERS_TO_ASSIGNER = {
      COLUMN_HEADERS[ALTERNATIVE_TITLE] => :alternative_title=,
      COLUMN_HEADERS[MISCELLANEOUS_CONDITION_TYPE] => :miscellaneous=,
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
      @spreadsheet_submission.update(failure_message: @parse_headers_msg, successful_submission: false, submission_progress: 100)
    else
      @cv = ControlledVocabulary.physical_object_cv('RecordedSound')
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
            @spreadsheet_submission.update(successful_submission: true, submission_progress: 100)
            @spreadsheet.update(successful_upload: true)
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
        @spreadsheet_submission.update(failure_message: error_msg, successful_submission: false, submission_progress: 100)
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
    po = RecordedSound.new(spreadsheet_id: @spreadsheet.id)
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
        po.send(:capacity=, tc)
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

    gauge = row[column_index GAUGE]
    if gauge.blank?
      po.errors.add(:gauge, "Recorded Sound Gauge cannot be blank!")
    elsif RecordedSound::GAUGE_VALUES.include?(gauge)
      set_value(:gauge, gauge, po)
    else
      po.errors.add(:gauge, ">#{gauge}< is not a valid Recorded Sound Gauge value")
    end

    part = row[column_index PART]
    unless part.blank?
      po.send(:part=, part)
    end

    detailed_stock_info = row[column_index DETAILED_STOCK_INFORMATION]
    unless detailed_stock_info.blank?
      po.send(:detailed_stock_information=, detailed_stock_info)
    end

    size = row[column_index SIZE]
    unless size.blank?
      if RecordedSound::SIZE_VALUES.include?(size)
        set_value(:size, size, po)
      else
        po.errors.add(:size, ">#{size}< is not a valid Recorded Sound Size value")
      end
    end

    playback_speed = row[column_index PLAYBACK_SPEED]
    unless playback_speed.blank?
      if RecordedSound::PLAYBACK_SPEEDS.include?(playback_speed)
        po.send(:playback=, playback_speed)
      else
        po.errors.add(:playback, ">#{playback_speed}< is not a valid Recorded Sound Playback value")
      end
    end

    # version
    version_fields = row[column_index VERSION].blank? ? [] : row[column_index VERSION].split(DELIMITER)
    version_fields.each do |vf|
      # these attributes are prepended with version_
      field = ("version_#{vf}").parameterize.underscore
      if RecordedSound::VERSION_FIELDS.include?(field.to_sym)
        po.send((field << "=").to_sym, true)
      else
        # it could be 1st - 4th edition which don't 'map' easily from attribute name to humanized text
        case field
        when "version_1st_edition"
          po.send(:version_first_edition=, true)
        when "version_2nd_edition"
          po.send(:version_second_edition=, true)
        when "version_3rd_edition"
          po.send(:version_third_edition=, true)
        when "version_4th_edition"
          po.send(:version_fourth_edition=, true)
        when "version_original"
          po.send(:version_original=, true)
        else
          po.errors.add(:version, "Undefined version: #{vf}")
        end
      end
    end

    # generation
    gen_fields = row[column_index GENERATION].blank? ? [] : row[column_index GENERATION].split(DELIMITER)
    gen_fields.each do |gf|
      if RecordedSound::GENERATION_FIELDS_HUMANIZED.values.include?(gf)
        sym = RecordedSound::GENERATION_FIELDS_HUMANIZED.key(gf)
        po.send((sym.to_s << "=").to_sym, true)
      else
        po.errors.add(:generation, "Undefined generation: #{gf}")
      end
    end

    # original identifiers
    o_ids = row[column_index ORIGINAL_IDENTIFIER].blank? ? [] : row[column_index ORIGINAL_IDENTIFIER].split(DELIMITER)
    o_ids.each do |id|
      po.physical_object_original_identifiers << PhysicalObjectOriginalIdentifier.new(identifier: id, physical_object_id: po.id)
    end

    # base
    base = row[column_index BASE]
    unless base.blank?
      if RecordedSound::BASE_FIELDS_HUMANIZED.values.include?(base)
        po.send(:base=, base)
      else
        po.errors.add(:base, "Undefined base: #{base}")
      end
    end
    # stock
    stock = row[column_index STOCK]
    unless stock.blank?
      if RecordedSound::STOCK_VALUES.include?(stock)
        po.stock = stock
      else
        po.errors.add(:stock, ">#{stock}< is not a valid Recorded Sound Stock value")
      end
    end

    # sound content type
    content_fields = row[column_index SOUND_CONTENT_TYPE].blank? ? [] : row[column_index SOUND_CONTENT_TYPE].split(DELIMITER)
    content_fields.each do |cf|
      field = "sound content type #{cf}".parameterize.underscore
      if RecordedSound::SOUND_CONTENT_FIELDS.include?(field.to_sym)
        po.send((field << "=").to_sym, true)
      else
        po.errors.add(:sound_content_type, ">#{cf}< is not a valid Recorded Sound 'Sound Content Type' value")
      end
    end

    # sound configuration
    config_fields = row[column_index SOUND_CONFIGURATION].blank? ? [] : row[column_index SOUND_CONFIGURATION].split(DELIMITER)
    config_fields.each do |cf|
      field = "sound configuration #{cf}".parameterize.underscore
      if RecordedSound::SOUND_CONFIGURATION_FIELDS.include?(field.to_sym)
        po.send((field << "=").to_sym, true)
      else
        po.errors.add(:sound_configuration, ">#{cf}< is not a valid Recorded Sound 'Sound Configuration' value")
      end
    end

    # language fields - RecordedSound languages do not have a type
    lang_fields = row[column_index LANGUAGE].blank? ? [] : row[column_index LANGUAGE].split(DELIMITER)
    langs = @l_cv[:language].collect { |x| x[0].downcase }
    lang_fields.each do |lf|
      index = langs.find_index(lf.downcase)
      if ! index.nil?
        po.languages << Language.new(language: @l_cv[:language][index][0], physical_object_id: po.id)
      else
        po.errors.add(:dialog_language, "Undefined language: #{lf}")
      end
    end

    # condition type fields with value ranges or booleans
    condition_fields = row[column_index CONDITION_TYPE].blank? ? [] : row[column_index CONDITION_TYPE].split(DELIMITER)
    cv = ControlledVocabulary.physical_object_cv('RecordedSound')
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

    mold = row[column_index MOLD].blank? ? "" : row[column_index MOLD].strip
    mold_vals = @cv[:mold].collect{ |cv| cv[0]}
    if mold.length > 0
      if mold_vals.include?(mold)
        po.send(:mold=, mold)
      else
        po.errors.add(:mold, "Invalid mold value: '#{mold}'")
      end
    end

    nr = row[column_index NOISE_REDUCTION].blank? ? "" : row[column_index NOISE_REDUCTION].strip
    nr_vals = @cv[:noise_reduction].collect{|cv| cv[0]}
    if nr.length > 0
      if nr_vals.include?(nr)
        po.send(:noise_reduction=, nr)
      else
        po.errors.add(:noise_reduction, "#{nr} is not a valid Noise Reduction value")
      end
    end

    sides = row[column_index SIDES].blank? ? "" : row[column_index SIDES].strip
    sides_vals = @cv[:sides].collect{|cv| cv[0]}
    if sides.length > 0
      if sides_vals.include?(sides)
        po.send(:sides=, sides)
      else
        po.errors.add(:sides, "#{sides} is not a valid Sides value")
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
      ws = WorkflowStatus.build_workflow_status(location, po)
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
      po.send(:accompanying_documentations, acd)
    end
  end

  def set_value(attr_symbol, val, po)
    unless val.blank?
      begin
        if @cv[attr_symbol].collect { |x| x[0] }.include? val
          po.send((attr_symbol.to_s << "=").to_sym, val)
        else
          po.errors.add(attr_symbol, "Invalid #{attr_symbol.to_s.humanize} value: #{val}")
        end
      rescue
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