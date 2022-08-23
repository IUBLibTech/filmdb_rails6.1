class AddMediumToPhysicalObject < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :medium, :string, nil: false
  end
end
