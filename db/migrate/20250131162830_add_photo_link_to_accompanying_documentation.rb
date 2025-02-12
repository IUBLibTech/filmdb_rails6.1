class AddPhotoLinkToAccompanyingDocumentation < ActiveRecord::Migration[6.1]
  def change
    add_column :accompanying_documentations, :photo_link, :text, limit: 2048
  end
end
