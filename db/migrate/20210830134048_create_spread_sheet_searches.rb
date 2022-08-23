class CreateSpreadSheetSearches < ActiveRecord::Migration[4.2]
  def change
    create_table :spread_sheet_searches do |t|
      # search parameters
      t.integer :user_id
      t.string :title_text
      t.string :series_name
      t.string :date_text
      t.string :publisher_text
      t.string :creator_text
      t.string :summary_text
      t.string :location_text
      t.string :subject_text
      t.integer :collection_id
      t.string :digitized_status

      # whether or not the job completed. nil if running or failed before it started,
      # false if the job failed, true iff the job completed
      t.boolean :completed

      # how long the query took to run in seconds
      t.float :query_runtime
      # how long it took to generate the spreadsheet
      t.float :spreadsheet_runtime

      # current completion state of the job
      t.integer :percent_complete

      # stack trace if there was an error while running the job
      t.text :error_message

      # the creation of SpreadSheetSearches happens as the result of a get. Adding a timestamp to the link so that
      # users clicking the back/forward button do not recreate the search and subsequent spreadsheet
      t.float :request_ts

      t.string :file_location
      t.timestamps null: false
    end
  end
end
