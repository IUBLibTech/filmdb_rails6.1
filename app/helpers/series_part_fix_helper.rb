module SeriesPartFixHelper
  require 'csv'
  BAD_BC_FILENAME = 'Bad Barcodes.csv'
  UNFOUND_FILENAME = "Unfound Titles.csv"
  BAD_BARCODES = []
  UNFOUND_TITLES = []
  # stores filename keys that map to an array of [BAD_BARCODES, UNFOUND_TITLES]
  REPORT = {}
  def parse_files
    ss = Dir.entries("tmp/ss").select { |f| File.extname(f) == '.csv'}.collect{ |f| "#{Dir.pwd}/tmp/ss/#{f}"}
    File.delete(BAD_BC_FILENAME) if File.exists?(BAD_BC_FILENAME)
    File.delete(UNFOUND_FILENAME) if File.exists?(UNFOUND_FILENAME)
    bcsv = CSV.open(BAD_BC_FILENAME, "wb")
    bcsv << ["Spreadsheet", "IU Barcode", "Row"]
    tcsv = CSV.open(UNFOUND_FILENAME, "wb")
    tcsv << ["Spreadsheet","IU Barcode", "Title", "Series Part"]
    Title.transaction do
      ss.each do |f|
        BAD_BARCODES.clear
        UNFOUND_TITLES.clear
        puts "Processing spreadsheet #{File.basename f}"
        parse_spreadsheet(f)
        if BAD_BARCODES.length > 0
          BAD_BARCODES.each do |bc|
            bcsv << [File.basename(f), bc[0], bc[1], "\n"]
          end
        end
        if UNFOUND_TITLES.length > 0
          UNFOUND_TITLES.each do |t|
            tcsv << [File.basename(f), t[0], t[1], t[2], t[3]]
          end
        end
      end
      bcsv.close
      tcsv.close
      puts "#{ss.size} spreadsheets processed"
    end
  end

  def parse_spreadsheet(f)
    begin
      @csv = CSV.read(f, headers: false)
    rescue
      opened_file = File.open(f, "r:ISO-8859-1:UTF-8")
      @csv = CSV.parse(opened_file, headers: false)
    end
    @headers = Hash.new
    # read all of the file's column headers and store the indexes of iu barcode, series part, and title
    @csv[0].each_with_index { |header, i|
      if ['IU Barcode', 'Series Part', 'Title'].include?(header)
        @headers[header.strip] = i
      end
    }
    @csv.each_with_index do |row, index|
      unless index == 0
        sp = row[@headers['Series Part']]
        unless sp.blank?
          title = row[@headers['Title']]
          bc = row[@headers['IU Barcode']]
          update_po(bc, title, sp, index + 1)
        end
      end
    end
  end

  def update_po(iu_barcode, title_text, series_part, row)
    po = PhysicalObject.where(iu_barcode: iu_barcode).first
    if po.nil?
      puts "Bad Barcode found: #{iu_barcode}"
      BAD_BARCODES << [iu_barcode, row]
    else
      t = po.titles.find { |t| t.title_text.include?(title_text)}
      if t.nil?
        puts "Bad Title found [#{t}] at row #{row}"
        UNFOUND_TITLES << [iu_barcode, title_text, series_part, row]
      else
        t.update_attributes(series_part: series_part)
      end
    end
  end
end
