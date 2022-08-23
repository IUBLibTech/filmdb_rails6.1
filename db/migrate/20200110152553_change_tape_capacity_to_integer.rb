class ChangeTapeCapacityToInteger < ActiveRecord::Migration[4.2]
  def up
    change_column :videos, :tape_capacity, :integer
  end

  def down
    change_column :videos, :tape_capacity, :string
  end
end
