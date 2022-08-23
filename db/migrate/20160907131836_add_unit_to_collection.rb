class AddUnitToCollection < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :unit_id, :integer, limit: 8
  end
end
