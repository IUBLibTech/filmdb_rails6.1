class FixComponentGroupCleanDefault < ActiveRecord::Migration[4.2]
  def up
    change_column_default :component_groups, :clean, 'Yes'
  end

  def down
    change_column_default :component_groups, :clean, 1
  end
end
