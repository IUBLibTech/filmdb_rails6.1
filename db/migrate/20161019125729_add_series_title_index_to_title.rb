class AddSeriesTitleIndexToTitle < ActiveRecord::Migration[4.2]
  def change
    add_column :titles, :series_title_index, :integer, null: true
  end
end
