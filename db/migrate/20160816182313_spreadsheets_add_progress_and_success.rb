class SpreadsheetsAddProgressAndSuccess < ActiveRecord::Migration[4.2]
  def change
    add_column :spreadsheets, :successful_upload, :boolean, default: false
  end
end
