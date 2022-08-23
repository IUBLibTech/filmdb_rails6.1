class ChangePhysicalObjectFootageToInteger < ActiveRecord::Migration[4.2]
  def up
    change_column :physical_objects, :footage, :integer
  end

  def down
    change_column :physical_objects, :footage, :string
  end
end
