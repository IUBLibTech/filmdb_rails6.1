class AddWorksiteLocationToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :worksite_location, :string
  end
end
