class AddColorSpaceToComponentGroup < ActiveRecord::Migration[4.2]
  def change
    add_column :component_groups, :color_space, :string
  end
end
