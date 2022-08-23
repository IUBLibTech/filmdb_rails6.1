class AddNameAuthorityToTitles < ActiveRecord::Migration[4.2]
  def change
    add_column :titles, :name_authority, :text, limit: 65535
  end
end
