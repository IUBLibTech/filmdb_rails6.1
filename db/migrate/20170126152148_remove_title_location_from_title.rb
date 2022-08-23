class RemoveTitleLocationFromTitle < ActiveRecord::Migration[4.2]
  def up
    remove_column :titles, :location
  end
  def down
    add_column :titles, :location, :string
  end
end
