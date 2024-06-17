class AddPhotoLink < ActiveRecord::Migration[6.1]
  def change
    add_column :physical_objects, :photo_link, :text
  end
end
