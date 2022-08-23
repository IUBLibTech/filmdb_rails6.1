class AddAlfShelfToPhysicalObject < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :alf_shelf, :string, default: nil
  end
end
