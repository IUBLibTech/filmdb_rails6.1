module RmdHelper
  include DateHelper
  include PhysicalObjectsHelper
  include ParserHelper
  require 'csv'

  SOURCE_PATH = "/home/andrew/Desktop/rmd_spreadsheets/"
  DESTINATION_PATH = File.join(SOURCE_PATH, "output")
  TEST = "Consolidated Copyright Complete Research 06232020.csv"

  def test
    unless File.exist?(DESTINATION_PATH)
      Dir.mkdir(DESTINATION_PATH)
    end
    csv = load_source_file(TEST)
    parse_csv(csv, TEST)
  end

  def load_directory
    unless File.exist?(DESTINATION_PATH)
      Dir.mkdir(DESTINATION_PATH)
    end
    Dir.children("/home/andrew/Desktop/rmd_spreadsheets").each do |file|
      csv = load_source_file(file)
      parse_csv(csv, file)
    end
  end

  def load_source_file(file)
    f = File.join(SOURCE_PATH, file)
    csv = nil
    puts "Reading #{f}"
    begin
      csv = CSV.read(f, headers: true)
    rescue CSV::MalformedCSVError
      puts "File was not UTF-8. Trying ISO-8859-1"
      enc = File.open(f, "r:ISO-8859-1")
      csv = CSV.parse(enc, headers: true)
    rescue Exception => e
      puts e.error_msg
      puts e.stack_trace.join("\n")
    end
    puts "Headers: #{csv.headers}\n\n\n"
    csv
  end

  # parses source file creating up to 3 new csv files based on sources contents
  def parse_csv(csv, source_filename)
    # title control numbers can be shared by more than one PO. to get barcodes to align when more that 1 PO has the same
    # TCN, this hash tracks how many POs have been read for a given TCN. nil means none so the PO in question would be
    # index 0 (pos[0]), 1 means one has been read already so the next PO to use would be pos[1], etc
    @tcn_to_count = Hash.new

    tcn_index = csv.headers.find_index "IUCat Title No."
    unless tcn_index >= 0
      raise "FAILED TO FIND INDEX OF IUCat Title No"
    end

    # 3 output files, good_csv contains TCN matches, maybe_csv contains either Cat Key matches or appending "a" to what
    # looks like a cat key and matching on TCN, bad_csv contains everything else
    good_csv = [csv.headers.dup]
    maybe_csv = [csv.headers.dup]
    bad_csv = [csv.headers.dup]

    (1..(csv.length - 1)).each { |x|
      puts "Row #{x} of #{csv.length - 1}"
      row = csv[x]
      tcn = row[tcn_index]
      po = which_po(PhysicalObject.where(title_control_number: tcn), tcn)

      # No TCN match
      if po.nil?
        # assume there is no match as it should map to a TCN
        if tcn.starts_with?("a")
          bad_row = row.dup
          bad_row << "No match on apparent TCN"
          bad_csv << bad_row
        else
          # try and match cat key
          pos = PhysicalObject.where(catalog_key: tcn)
          if pos.size > 0
            po = pos[0]
            maybe_row = row.dup
            maybe_row[csv.headers.find_index('IU Barcode')] = po.iu_barcode
            maybe_row[csv.headers.find_index('MDPI Barcode')] = po.mdpi_barcode
            maybe_row << "Matched Catalog Key"
            maybe_csv << maybe_row
          else
            # try to match TCN by prepending an "a"
            pos = PhysicalObject.where(title_control_number: "a#{tcn}")
            if pos.size > 0
              po = pos[0]
              maybe_row = row.dup
              maybe_row[csv.headers.find_index('IU Barcode')] = po.iu_barcode
              maybe_row[csv.headers.find_index('MDPI Barcode')] = po.mdpi_barcode
              maybe_row << "Matched TCN by prepending 'a'"
              maybe_csv << maybe_row
            else
              # no match at all
              bad_row = row.dup
              bad_row << "No match on anything"
              bad_csv << bad_row
            end
          end
        end
      else
        # TCN match
        good_row = row.dup
        good_row[csv.headers.find_index('IU Barcode')] = po.iu_barcode
        good_row[csv.headers.find_index('MDPI Barcode')] = po.mdpi_barcode
        good_csv << good_row
      end
    }
    i = source_filename.index(".csv")
    if good_csv.size > 1
      out = source_filename.insert(i, " (GOOD)")
      write_csv(good_csv, out)
    end
    if maybe_csv.size > 1
      out = source_filename.insert(i, " (MAYBE)")
      write_csv(maybe_csv, out)
    end
    if bad_csv.size > 1
      out = source_filename.insert(i, " (MAYBE)")
      write_csv(bad_csv, out)
    end
  end

  def write_csv(contents, filename)
    output = File.join(DESTINATION_PATH, filename)
    IO.write(output, contents.map(&:to_csv).join)
  end

  def which_po(pos, tcn)
    po = nil
    # single po so just return the first
    if pos.length == 1
      pos.first

    # multiple POS share a cat key so consult @tcn_to_count to determine which one we're looking at
    elsif pos.length > 1
      index = @tcn_to_count[tcn].nil? ? 0 : @tcn_to_count[tcn]
      po = pos[index]
      @tcn_to_count[tcn] = @tcn_to_count[tcn].nil? ? 1 : @tcn_to_count[tcn] + 1
    else
      # no match so fall through to return nil
    end
    po
  end

end