class RemoveReturnOnOriginalReel < ActiveRecord::Migration[4.2]
  def change
    remove_column :component_groups, :return_on_original_reel
  end
end
