class ChangePhysicalObjectCaptionsSubtitlesToText < ActiveRecord::Migration[4.2]
  def change
	  add_column :physical_objects, :close_caption_text, :string
    PhysicalObject.where(close_caption: false).update_all(close_caption_text: '')
	  PhysicalObject.where(close_caption: true).update_all(close_caption_text: 'Yes')
	  remove_column :physical_objects, :close_caption
	  rename_column :physical_objects, :close_caption_text, :close_caption
  end
end
