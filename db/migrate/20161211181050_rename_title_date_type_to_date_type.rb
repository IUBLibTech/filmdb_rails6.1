class RenameTitleDateTypeToDateType < ActiveRecord::Migration[4.2]
  def up
    rename_column :title_dates, :type, :date_type
  end

  def down
    rename_column :title_dates, :date_type, :type
  end
end
