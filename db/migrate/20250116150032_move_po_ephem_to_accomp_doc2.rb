class MovePoEphemToAccompDoc2 < ActiveRecord::Migration[6.1]
  include SpreadsheetUpdaterHelper
  require "roo"

  # this migration moves physical object ephemera metadata into accompanying documentation metadata associated either
  # with the po (first group), or FIRST po Title (second group)
  def up
    AccompanyingDocumentation.transaction do
      # po ephem to po AD
      path = "#{ Rails.root }/tmp/po_ephem_to_po_ad.xlsx"
      puts "Processing: #{path}"
      do_it(path, PhysicalObject)
      if @bad.size > 0
        puts "**************************"
        puts "   Migration FAILED!!!   "
        puts "**************************"
        @bad.each do |bc|
          puts "\t#{bc} failed!"
        end
        raise "Some/all barcodes failed in this migration. Transaction was rolled back."
      end


      # po ephemera to Title AD
      path = "#{ Rails.root }/tmp/po_ephem_to_title_ad.xlsx"
      puts "Processing: #{path}"
      do_it(path, Title)
      if @bad.size > 0
        puts "**************************"
        puts "   Migration FAILED!!!   "
        puts "**************************"
        @bad.each do |bc|
          puts "\t#{bc} failed!"
        end
        raise "Some/all barcodes failed in this migration. Transaction was rolled back."
      end
    end
  end


  # the is no down for this one...

  private
  def do_it(spreadsheet, ad_type)
    # po AD
    @bad = []

    if File.exist? spreadsheet
      x = Roo::Spreadsheet.open(spreadsheet, extension: :xlsx)
      x.default_sheet = x.sheets[0]
      for i in 1..x.last_row do
        bc = x.row(i)[0].to_int
        puts "\t#{i} of #{x.last_row} - Processing #{bc}"
        AccompanyingDocumentation.transaction do
          begin
            if ad_type == PhysicalObject
              po_ephemera_to_po_accompanying_documentation(bc)
            elsif ad_type == Title
              po_ephemera_to_title_accompanying_documentation(bc)
            end
          rescue => e
            @bad << [bc, e.message]
          end
        end
      end
    else
      puts "\n\n\n**********************************************************************************************"
      puts "   WARNING: file not found: #{spreadsheet} - SKIPPING this migration   "
      puts "**********************************************************************************************\n\n\n"
    end
  end

end
