class AddSubjectToTitles < ActiveRecord::Migration[4.2]
  def change
    add_column :titles, :subject, :text, limit: 65535
  end
end
