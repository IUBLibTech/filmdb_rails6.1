class PhysicalObjectBelongsToSpreadsheet < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :spreadsheet_id, :integer, null: true
  end
end
