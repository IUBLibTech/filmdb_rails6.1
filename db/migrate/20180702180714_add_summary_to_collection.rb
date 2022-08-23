class AddSummaryToCollection < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :summary, :text, limit: 65535
  end
end
