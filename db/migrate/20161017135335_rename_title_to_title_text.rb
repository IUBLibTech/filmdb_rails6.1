class RenameTitleToTitleText < ActiveRecord::Migration[4.2]
  def change
    rename_column :titles, :title, :title_text
  end
end
