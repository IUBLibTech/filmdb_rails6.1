module RmdXslxHelper
  require "roo"
  require "csv"

  require "application_helper"

  # catalog key constance
  CAT_KEY = "cat_key"
  # IU Barcode key constance
  IU_BARCODE = "iubc"
  # MDPI Barcode key constance
  MDPI_BARCODE = "mdpibc"
  # Original Identifier key constant
  ORIGINAL_ID = "oid"

  # For the IUCAT report spreadsheet, header value mapped to its 0-based index in the row (for instance, cat key can be found in the second column)
  CAT_HEADERS = {
    CAT_KEY => 1,
    IU_BARCODE => 20
  }

  # for the IULMIA consolidate spreadsheet (the one with bad data), maps column header to its 0-based index in the spreadsheet
  IULMIA_HEADERS = {
    IU_BARCODE => 2,
    MDPI_BARCODE => 3,
    ORIGINAL_ID => 5,
    CAT_KEY => 10
  }

  # for the POD report of IULMIA content, maps the above keys (CAT_KEY, IU_BARCODE, etc) to their 0-based column index in the spreadsheet
  POD_HEADERS = {
    CAT_KEY => 0,
    IU_BARCODE => 1,
    MDPI_BARCODE => 2
  }

  # maps IUCAT title control number to an IU barcode
  IUCAT_KEY_MAP = {}
  # maps POD report records cat key => [iu_barcode, mdpi_barcode]
  POD_KEY_MAP = {}

  # the IULMIA header row from their source file
  @IULMIA_HEADER = []

  # items found in both spreadsheets based on cat key or IU barcode, or MDPI barcode
  GOOD = []
  # items where a partial match was made based on original identifier - these should be manually reviewed by a human
  REVIEW = []
  # items that could not be found by any means
  BAD = []
  # items in the consolidated spreadsheet that do NOT have any value for IUCat Title No.
  NO_KEY = []

  COUNTS = {
    "GOOD" => 0,
    "REVIEW" => 0,
    "BAD" => 0,
  }

  def self.do_it
    load_cat
    load_pod
    load_iulmia
    write_good
    write_review
    write_bad
    COUNTS.keys.each do |k|
      puts "#{k}: #{COUNTS[k]}"
    end
  end

  # loads the IUCAT report and maps cat key to IU Barcode if the barcode is valid (not one of the auto-assigned
  # IUCAT identifier numbers 2313290-2001 for instance)
  def self.load_cat
    puts "Loading IUCAT file..."
    sheet = Roo::Spreadsheet.open("#{Rails.root}/tmp/rmd/IULMIA ITEM CAT.xlsx", extension: :xlsx)
    sheet.default_sheet = sheet.sheets[0]

    i = 2 # skip the header row
    while (i <= sheet.last_row)
      row = sheet.row(i)
      cat_key = row[CAT_HEADERS[CAT_KEY]]
      iu_barcode = row[CAT_HEADERS[IU_BARCODE]]
      if ApplicationHelper.valid_barcode?(iu_barcode, false)
        IUCAT_KEY_MAP[cat_key] = iu_barcode
      end
      i += 1
    end
    puts "\tDone!"
  end


  # reads the pod report xslx file into a hash mapping cat_key to IU barcode, IFF the IU barcode present in POD is a VALID
  # barcode: some of the records in POD contain IUCAT auto-generated barcodes
  def self.load_pod
    puts "Loading POD File..."
    x = Roo::Spreadsheet.open("#{Rails.root}/tmp/rmd/pod_records.xlsx", extension: :xlsx)
    x.default_sheet = x.sheets[0]
    i = 2
    while (i <= x.last_row)
      row = x.row(i)
      cat_key = row[POD_HEADERS[CAT_KEY]]
      if (cat_key.to_s.start_with?("a"))
        cat_key = cat_key.to_s(1..-1).to_i
      end

      # the pod report has some instances where the IU Barcode is IUCAT auto-assigned but there is a valid MDPI Barcode present
      # make sure to map cat key to an array of both types, replacing bad barcodes with nil
      bc = row[POD_HEADERS[IU_BARCODE]]
      mbc = row[POD_HEADERS[MDPI_BARCODE]]
      unless bc != nil && ApplicationHelper.valid_barcode?(bc, false)
        bc = nil
      end
      unless mbc != nil && ApplicationHelper.valid_barcode?(mbc, true)
        mbc = nil
      end
      store = [bc, mbc]
      POD_KEY_MAP[cat_key] = store
      i += 1
    end
    puts "\tDone"
  end

  # loads the IULMIA consolidated spreadsheet and then parses row by row to attempt a match
  def self.load_iulmia
    puts "Loading IULMIA Consolidated File"
    x = Roo::Spreadsheet.open("#{Rails.root}/tmp/rmd/Consolidated Copyright Complete Research 06232020.xlsx", extension: :xlsx)
    x.default_sheet = x.sheets[0]
    parse_iulmia(x)
  end

  def self.parse_iulmia(sheet)
    @IULMIA_HEADER = sheet.row(1)
    i = 2
    while (i <= sheet.last_row)
      row = sheet.row(i)
      puts "IULMIA Row: #{i}"
      cat_key = row[IULMIA_HEADERS[CAT_KEY]]
      # sanitize title control numbers so they are cat keys
      if !cat_key.blank? && cat_key.to_s.start_with?("a")
        cat_key = cat_key[1..-1].to_i
      end
      bc = row[IULMIA_HEADERS[IU_BARCODE]]
      mbc = row[IULMIA_HEADERS[MDPI_BARCODE]]
      oid = row[IULMIA_HEADERS[ORIGINAL_ID]]

      # perform these steps
      # 1) check if there is a valid IU or MDPI Barcode in the IULMIA spreadsheet
      # 2) if above fails, check IULMIA cat key against IUCAT report
      # 3) if above fails, check IULMIA cat key against POD report. If steps 1-3 succeed, record in the GOOD array
      # 4) if above fails, check IULMIA original identifier against Filmdb and record all matches in the REVIEW array
      # %) if all of the above fails, record in the FAILED array

      po = check_iu_barcode(bc)
      if po.nil?
        po = check_mdpi_barcode(mbc)
        if po.nil?
          po = check_iucat(cat_key)
          if po.nil?
            po = check_pod(cat_key)
            if po.nil?
              # finally check if we can get matches on original ids
              pos = check_original_id(oid)
              if pos.nil?
                row << "Failed all matching strategies"
                BAD << row
                COUNTS["BAD"] = COUNTS["BAD"] + 1
              else
                row[IULMIA_HEADERS[IU_BARCODE]] = pos[0]
                row << pos[1]
                REVIEW << row
                COUNTS["REVIEW"] = COUNTS["REVIEW"] + 1
              end
            else
              set_row_data(row, po)
              COUNTS["GOOD"] = COUNTS["GOOD"] + 1
            end
          else
            set_row_data(row, po)
            COUNTS["GOOD"] = COUNTS["GOOD"] + 1
          end
        else
          set_row_data(row, po)
          COUNTS["GOOD"] = COUNTS["GOOD"] + 1
        end
      else
        set_row_data(row, po)
        COUNTS["GOOD"] = COUNTS["GOOD"] + 1
      end
      i += 1
    end
  end

  # the incoming array is [PhysicalObject, String with message about the map]
  def self.set_row_data(row, array)
    row[IULMIA_HEADERS[IU_BARCODE]] = array[0].iu_barcode
    row[IULMIA_HEADERS[MDPI_BARCODE]] = array[0].mdpi_barcode
    row << array[1]
    GOOD << row
  end

  def self.check_iu_barcode(bc)
    if bc != nil && ApplicationHelper.valid_barcode?(bc, false)
      po = PhysicalObject.where(iu_barcode: bc)&.first
      if po.nil?
        return nil
      else
        return [po, "IU Barcode in original file"]
      end
    end
  end
  def self.check_mdpi_barcode(mbc)
    if mbc != nil && ApplicationHelper.valid_barcode?(mbc, true)
      po = PhysicalObject.where(iu_barcode: mbc)&.first
      if po.nil?
        return nil
      else
        return [po, "MDPI Barcode in original file"]
      end
    end
  end

  def self.check_iucat(cat_key)
    bc = IUCAT_KEY_MAP[cat_key]
    return nil if bc.nil?
    # two possibilities here:
    # a) there is a valid IU Barcode mapped from the cat key
    # b) barcode is an auto-generated IUCAT "barcode". In many cases POD has this auto-gen'd "barcode" in it's record so
    # compare cat_key to POD map
    if bc.to_s.include?("-")
      po = PhysicalObject.where(mdpi_barcode: POD_KEY_MAP[cat_key])&.first
      return nil if po.nil?
      return [po, "Cat key match: IUCAT auto-generated barcode matched against POD"]
    else
      po = PhysicalObject.where(iu_barcode: bc)&.first
      return nil if po.nil?
      return [po, "Cat key matched: IUCAT report"]
    end
  end

  def self.check_pod(cat_key)
    bcs = POD_KEY_MAP[cat_key]
    return nil if bcs.nil?
    # POD should ALWAYS have an MDPI barcode for its records
    po = PhysicalObject.where(mdpi_barcode: bcs[1])&.first
    return nil if po.nil?
    return [po, "Cat ket matched: POD report"]
  end

  def self.check_original_id(oid)
    pos = PhysicalObject.joins(:physical_object_original_identifiers).where(physical_object_original_identifiers: {identifier: oid}).pluck(:iu_barcode)
    return [pos.join(", "), "Original Id match"] if pos.size > 0
    return nil
  end



  def self.write_good
    good = "#{Rails.root}/tmp/rmd/matches.csv"
    CSV.open(good, 'w') do |w|
      w << @IULMIA_HEADER
      GOOD.each do |r|
        w << r
      end
    end
  end

  def self.write_review
    review = "#{Rails.root}/tmp/rmd/review.csv"
    CSV.open(review, 'w') do |w|
      w << @IULMIA_HEADER
      REVIEW.each do |r|
        w << r
      end
    end
  end

  def self.write_bad
    bad = "#{Rails.root}/tmp/rmd/no matches.csv"
    CSV.open(bad, 'w') do |w|
      w << @IULMIA_HEADER
      BAD.each do |row|
        w << row
      end
    end
  end

end