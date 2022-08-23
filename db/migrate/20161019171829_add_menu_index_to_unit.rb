class AddMenuIndexToUnit < ActiveRecord::Migration[4.2]
  def change
    add_column :units, :menu_index, :integer, null: true
  end
end
