class RenameTypeToConditionType < ActiveRecord::Migration[4.2]
  def up
    rename_column :value_conditions, :type, :condition_type
    rename_column :boolean_conditions, :type, :condition_type
  end

  def down
    rename_column :value_conditions, :condition_type, :type
    rename_column :boolean_conditions, :condition_type, :type
  end
end
