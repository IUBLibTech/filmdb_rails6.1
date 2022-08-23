class RemoveVideoTimestamps < ActiveRecord::Migration[4.2]
  def change
    remove_column :videos, :created_at
    remove_column :videos, :updated_at
  end
end
