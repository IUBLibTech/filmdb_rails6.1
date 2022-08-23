class AddTapeCapacityToVideo < ActiveRecord::Migration[4.2]
  def change
    add_column :videos, :tape_capacity, :string
  end
end
