class AddGenerationMasterToPhysicalObject < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :generation_master, :boolean, null: true
  end
end
