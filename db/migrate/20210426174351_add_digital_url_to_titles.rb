class AddDigitalUrlToTitles < ActiveRecord::Migration[4.2]
  def change
    add_column :titles, :stream_url, :string
  end
end
