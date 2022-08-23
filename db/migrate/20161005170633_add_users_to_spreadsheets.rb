class AddUsersToSpreadsheets < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :created_in_spreadsheet, :integer, limit: 8
  end
end
