class AddFlagToCaiaSoftItemLoc < ActiveRecord::Migration[8.0]
  def change
    add_column :caia_soft_item_locs, :mismatch, :boolean
  end
end
