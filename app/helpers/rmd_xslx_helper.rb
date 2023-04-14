module RmdXslxHelper
  require "roo"
  require "csv"

  CAT_HEADERS = ["Catalog Key", "Title", "Item ID"]
  IULMIA_HEADERS = ["IUCat Title No.", "IU Barcode"]
  # maps a CAT_HEADER value to its col index in the header row
  HEADERS = {}
  # MAPS an IULMIA_HEADERS value to its col index in a row
  IUL_HEADERS = {}
  # maps IUCAT title control number to an array containing Title and IU barcode
  KEY_MAP = {}

  # the IULMIA header row from their source file
  IULMIA_HEADER = []
  # items found in both spreadsheets based on cat key
  GOOD = []
  # items not found from IULMIA spreadsheet
  BAD = []

  def self.load_cat
    x = Roo::Spreadsheet.open("#{Rails.root}/tmp/rmd/IULMIA ITEM CAT.xlsx", extension: :xlsx)
    x.default_sheet = x.sheets[0]
    find_headers(x)
    parse_cat_rows(x)

    load_iulmia

  end

  def self.load_iulmia
    x = Roo::Spreadsheet.open("#{Rails.root}/tmp/rmd/Consolidated Copyright Complete Research 06232020.xlsx", extension: :xlsx)
    x.default_sheet = x.sheets[0]
    find_iulmia_headers(x)
    parse_iulmia(x)
    puts "Matched #{GOOD.size}"
    puts "\tFailed to match #{BAD.size}"
    write_good
    write_bad
  end

  def self.write_good
    good = "#{Rails.root}/tmp/rmd/good.csv"
    CSV.open(good, 'w') do |w|
      w << IULMIA_HEADER[0]
      GOOD.each do |r|
        w << r
      end
    end
  end

  def self.write_bad
    bad = "#{Rails.root}/tmp/rmd/bad.csv"
    CSV.open(bad, 'w') do |w|
      w << IULMIA_HEADER[0]
      BAD.each do |row|
        w << row
      end
    end
  end

  def self.find_headers(sheet)
    h = sheet.row(1)
    h.each_with_index do |c, i|
      if c == CAT_HEADERS[0]
        HEADERS[CAT_HEADERS[0]] = i
      elsif c == CAT_HEADERS[1]
        HEADERS[CAT_HEADERS[1]] = i
      elsif c == CAT_HEADERS[2]
        HEADERS[CAT_HEADERS[2]] = i
      end
    end
  end

  def self.parse_cat_rows(sheet)
    i = 2
    while (i <= sheet.last_row)
      row = sheet.row(i)
      parse_row(row)
      i += 1
    end
  end

  def self.parse_row(row)
    key = row[HEADERS[CAT_HEADERS[0]]]
    title = row[HEADERS[CAT_HEADERS[1]]]
    barcode = row[HEADERS[CAT_HEADERS[2]]]
    KEY_MAP[key] = [title, barcode]
  end

  def self.find_iulmia_headers(sheet)
    h = sheet.row(1)
    IULMIA_HEADER << h
    h.each_with_index do |c, i|
      if c == IULMIA_HEADERS[0]
        IUL_HEADERS[IULMIA_HEADERS[0]] = i
      elsif c == IULMIA_HEADERS[1]
        IUL_HEADERS[IULMIA_HEADERS[1]] = i
      end
    end
    puts IUL_HEADERS
  end

  def self.parse_iulmia(sheet)
    i = 2
    while (i <= sheet.last_row)
      row = sheet.row(i)
      puts "IULMIA Row: #{i}"
      key = row[IUL_HEADERS[IULMIA_HEADERS[0]]]
      bc = row[IUL_HEADERS[IULMIA_HEADERS[1]]]
      if KEY_MAP[key].nil?
        # no match
        BAD << row
      else
        # a match so update the barcode value and stick it in good
        row[IUL_HEADERS[IULMIA_HEADERS[1]]] = KEY_MAP[key][1]
        GOOD << row
      end
      i += 1
    end
  end

end