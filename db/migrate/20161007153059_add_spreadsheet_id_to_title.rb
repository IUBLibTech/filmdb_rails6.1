class AddSpreadsheetIdToTitle < ActiveRecord::Migration[4.2]
  def change
    add_column :titles, :spreadsheet_id, :integer, limit: 8
  end
end
