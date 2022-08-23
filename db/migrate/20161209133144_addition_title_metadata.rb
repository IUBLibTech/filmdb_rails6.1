class AdditionTitleMetadata < ActiveRecord::Migration[4.2]
  def change
    add_column :titles, :modified_by_id, :integer, limit: 8
    add_column :titles, :series_part, :string
    add_column :titles, :title_original_identifier, :string
    rename_column :titles, :description, :summary
    add_column :titles, :creator, :string
    add_column :titles, :location, :string
    add_column :titles,  :notes, :text
  end
end
