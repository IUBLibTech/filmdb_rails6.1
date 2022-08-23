class AddNarrationOtherTitlesToPhysicalObjects < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :picture_titles, :boolean
    add_column :physical_objects, :generation_other, :boolean
    add_column :physical_objects, :sound_content_narration, :boolean
  end
end
