class ReadOnlyUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :read_only, :boolean
  end
end
