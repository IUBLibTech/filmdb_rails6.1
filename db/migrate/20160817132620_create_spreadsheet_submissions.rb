class CreateSpreadsheetSubmissions < ActiveRecord::Migration[4.2]
  def change
    create_table :spreadsheet_submissions do |t|
      t.integer :spreadsheet_id
      t.integer :submission_progress
      t.boolean :successful_submission
      t.text :failure_message
      t.timestamps
    end
  end
end
