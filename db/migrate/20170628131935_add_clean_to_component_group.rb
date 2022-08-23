class AddCleanToComponentGroup < ActiveRecord::Migration[4.2]
  def change
    add_column :component_groups, :clean, :boolean, default: true
  end
end
