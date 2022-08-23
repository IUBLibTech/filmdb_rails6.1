class AddSpreadsheetIdToSeries < ActiveRecord::Migration[4.2]
  def change
    add_column :series, :spreadsheet_id, :integer, limit: 8
  end
end
