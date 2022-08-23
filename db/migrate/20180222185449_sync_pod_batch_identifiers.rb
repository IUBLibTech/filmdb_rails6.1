class SyncPodBatchIdentifiers < ActiveRecord::Migration[4.2]
  require 'csv'
  def up
    puts "#{Dir.pwd}"
    if File.exist?("./tmp/cageShelfIdentifiers.csv")
      begin
        @csv = CSV.read("./tmp/cageShelfIdentifiers.csv", headers: false)
      rescue
        opened_file = File.open("./tmp/cageShelfIdentifiers.csv", "r:ISO-8859-1:UTF-8")
        @csv = CSV.parse(opened_file, headers: false)
      end
      CageShelf.transaction do
        @csv.each_with_index do |row, index|
          unless index == 0
            bc = row[0]
            ident = row[1]
            CageShelf.where(mdpi_barcode: bc).update_all(identifier: ident)
          end
        end
      end
    end
  end
  def down
    # there is no spoon
  end
end
