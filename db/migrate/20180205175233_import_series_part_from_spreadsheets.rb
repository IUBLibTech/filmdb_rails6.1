class ImportSeriesPartFromSpreadsheets < ActiveRecord::Migration[4.2]
  include SeriesPartFixHelper
  def up
    # this migration is no longer necessary. The database data has been corrected and the source spreadsheets
    # that held the corrections no longer exist
    # parse_files
  end
  def down
    #there is no down...
  end
end
