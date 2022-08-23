class AddScanResToComponentGroup < ActiveRecord::Migration[4.2]
  def change
    add_column :component_groups, :scan_resolution, :text, nil: true
  end
end
