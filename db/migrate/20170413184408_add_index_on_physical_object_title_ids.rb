class AddIndexOnPhysicalObjectTitleIds < ActiveRecord::Migration[4.2]
  def change
    add_index :physical_object_titles, [:physical_object_id, :title_id], unique: true
  end
end
