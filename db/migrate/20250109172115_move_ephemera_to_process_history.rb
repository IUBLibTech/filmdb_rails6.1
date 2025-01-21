class MoveEphemeraToProcessHistory < ActiveRecord::Migration[6.1]
  include SpreadsheetUpdaterHelper
  require "roo"

  def up
    bad = []
    PhysicalObject.transaction do
      path = "#{Rails.root}/tmp/ephemera_to_processing_notes.xlsx"
      if File.exist? path
        x = Roo::Spreadsheet.open(path, extension: :xlsx)
        x.default_sheet = x.sheets[0]
        i = 1
        while (i <= x.last_row)
          bc = x.row(i)[0].to_int
          puts "\t#{i} Processing #{bc}"
          PhysicalObject.transaction do
            begin
              reassign_po_attributes(bc, {:miscellaneous => :accompanying_documentation})
            rescue => e
              bad << [bc, e.message]
            end
            raise Exception("Failed migration because there were errors with the some of the barcodes (see list)") if bad.size > 0
          end
          i += 1
        end
      else
        puts "\n\n\n**********************************************************************************************"
        puts "   WARNING: Ephemera to processing notes migration file not found - skipping this migration   "
        puts "**********************************************************************************************\n\n\n"
      end
    end
    if bad.size > 0
      bad.each do |b|
        puts "#{b[0]} failed: #{b[1]}"
      end
    end
  end

  def down

  end
end
