class AdAdStripTimestampToFilm < ActiveRecord::Migration[6.1]
  def change
    add_column :films, :ad_strip_timestamp, :date
  end
end
