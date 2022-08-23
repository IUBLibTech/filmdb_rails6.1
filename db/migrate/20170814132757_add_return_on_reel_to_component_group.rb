class AddReturnOnReelToComponentGroup < ActiveRecord::Migration[4.2]
  def change
    add_column :component_groups, :return_on_reel, :boolean, default: false
  end
end
