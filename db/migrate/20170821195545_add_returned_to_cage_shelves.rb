class AddReturnedToCageShelves < ActiveRecord::Migration[4.2]
  def change
    add_column :cage_shelves, :returned, :boolean, default: false
  end
end
