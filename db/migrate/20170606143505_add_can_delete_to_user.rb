class AddCanDeleteToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :can_delete, :boolean, default: false
  end
end
