class AddPictureTypeTextToFilms < ActiveRecord::Migration[4.2]
  def change
    add_column :films, :picture_text, :boolean
  end
end
