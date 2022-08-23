class PhysicalObjectRenameUserToInventoriedBy < ActiveRecord::Migration[4.2]
  def change
    rename_column :physical_objects, :user_id, :inventoried_by
  end
end
