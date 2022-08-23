class SeriesNewMetadataFields < ActiveRecord::Migration[4.2]
  def change
    rename_column :series, :description, :summary
    add_column :series, :created_by_id, :integer, limit: 8
    add_column :series, :modified_by_id, :integer, limit: 8
    add_column :series, :production_number, :string
    add_column :series, :date, :string
    add_column :series, :total_episodes, :integer
  end
end
