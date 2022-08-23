class AddCanUpdateLocationToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :can_update_physical_object_location, :boolean, default: false
  end
end
