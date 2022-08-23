class ChangeHandCleanToText < ActiveRecord::Migration[4.2]
  def change
    clean_vals = {}
    ComponentGroup.all.each do |cg|
      clean_vals[cg.id] = cg.clean
    end
    change_column :component_groups, :clean, :string
    ComponentGroup.reset_column_information
    clean_vals.keys.each do |k|
      v = clean_vals[k]
      ComponentGroup.find(k).update(clean: k ? "Yes" : "No")
    end
  end
end
