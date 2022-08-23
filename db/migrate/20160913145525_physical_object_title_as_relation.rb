class PhysicalObjectTitleAsRelation < ActiveRecord::Migration[4.2]
  def up
    remove_column :physical_objects, :title
    add_column :physical_objects, :title_id, :integer, limit: 8
  end

  def down
    remove_column :physical_objects, :title_id
    add_column :physical_objects, :title, :string
  end
end
