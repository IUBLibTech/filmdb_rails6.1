class AddMutipleLocationToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :works_in_both_locations, :boolean, default: false
  end
end
