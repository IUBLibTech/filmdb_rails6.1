module FixSpreadsheetBugHelper
  require 'csv'
  BAD_LOG_FILENAME = 'Bad Barcodes Log.csv'
  HEADERS = ['IU Barcode', 'Title', 'Subject', 'Name Authority', 'Generation Notes', 'Catalog Key']
  def parse_files
    ss = Dir.entries("tmp/ss").select { |f| File.extname(f) == '.csv'}.collect{ |f| "#{Dir.pwd}/tmp/ss/#{f}"}
    File.delete(BAD_LOG_FILENAME) if File.exists?(BAD_LOG_FILENAME)
    @bcsv = CSV.open(BAD_LOG_FILENAME, "wb")
    @bcsv << ["IU Barcode","Spreadsheet Name", "Row", "Reason for Failure"]
    @bad_ss = []
    Title.transaction do
      ss.each do |f|
        parse_spreadsheet f
      end
    end
    if @bad_ss.length > 0
      File.open('Bad Spreadsheets.txt', "wb") do |f|
        @bad_ss.each do |bad|
          f.puts "#{bad}\n"
        end
      end
    end
    @bcsv.close
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
      if !header.nil? && HEADERS.include?(header.strip)
        @headers[header.strip] = i
      end
    }
    if @headers.keys.size != HEADERS.length
      @bad_ss << f
      return
    end
    @csv.each_with_index do |row, index|
      unless index == 0
        bc = row[@headers['IU Barcode']]
        po = PhysicalObject.where(iu_barcode: bc).first
        if po.nil?
          id = PhysicalObjectOldBarcode.where(iu_barcode: bc).last&.physical_object_id
          po = PhysicalObject.find(id) unless id.nil?
        end
        if po.nil?
          # ["IU Barcode","Spreadsheet Name", "Row", "Reason for Failure"]
          @bcsv << [bc, f.split('/').last, index + 1, "Could not match IU Barcode"]
        else
          po.update_attributes(catalog_key: (row[@headers['Catalog Key']].nil? ? nil : row[@headers['Catalog Key']].to_i))
          if all_blank?(row)
            next
          elsif row[@headers['Title']].include?(' | ')
            @bcsv << [bc, f.split('/').last, index + 1, "PO has multiple titles in spreadsheet"]
          elsif po.titles.size == 0
            @bcsv << [bc, f.split('/').last, index + 1, "PO has 0 Titles in Filmdb", "SS Title: #{row[@headers['Title']]}"]
          elsif po.titles.size > 1
            @bcsv << [bc, f.split('/').last, index + 1, "PO has multiple titles in Filmdb"]
          elsif po.titles.first.title_text != row[@headers['Title']]
            @bcsv << [bc, f.split('/').last, index + 1, "Title mismatch", "SS Title: #{row[@headers['Title']]}\nFilmdb Title: #{po.titles.first.title_text}"]
          elsif po.titles.first.digitized?
            # po.update_attributes(generation_notes: row[@headers['Generation Notes']])
            @bcsv << [bc, f.split('/').last, index + 1, "PO Generation Notes and Catalog Key were corrected, but Title was digitized - manually check Subject and Name Authority fields"]
          else
            po.update_attributes(generation_notes: row[@headers['Generation Notes']], catalog_key: row[@headers['Catalog Key']])
            po.titles.first.update_attributes(subject: row[@headers['Subject']], name_authority: row[@headers['Name Authority']])
          end
        end
      end
    end
  end

  def all_blank?(row)
    row[@headers['Subject']].blank? && row[@headers['Name Authority']].blank? &&  row[@headers['Generation Notes']].blank?
  end
end
