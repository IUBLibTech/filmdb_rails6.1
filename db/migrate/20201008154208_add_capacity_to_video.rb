class AddCapacityToVideo < ActiveRecord::Migration[4.2]
  def change
    add_column :recorded_sounds, :capacity, :string
  end
end
