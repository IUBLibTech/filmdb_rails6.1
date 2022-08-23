class AddGroupSummaryToComponentGroup < ActiveRecord::Migration[4.2]
  def change
    add_column :component_groups, :group_summary, :text, limit: 65535
  end
end
