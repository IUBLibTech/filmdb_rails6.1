class SpreadsheetUniqueFilename < ActiveRecord::Migration[4.2]
  def change
    add_index :spreadsheets, :filename, unique: true
  end

end
