class DropDurationFromVideo < ActiveRecord::Migration[4.2]
  def up
    remove_column :videos, :duration
  end

  def down
    add_column :videos, :duration, :integer
  end
end
