class AddGenreToSpreadsheetSearch < ActiveRecord::Migration[6.1]
  def change
    add_column :spread_sheet_searches, :genre, :string
  end
end
