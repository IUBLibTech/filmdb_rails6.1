class AddMediumFilterToSpreadsheetSearch < ActiveRecord::Migration[6.1]
  def change
    add_column :spread_sheet_searches, :medium_filter, :integer
  end
end
