class AddChannelingToPhysicalObjectConditionTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :channeling, :string
  end
end
