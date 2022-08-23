class SetShrinkagePrecision < ActiveRecord::Migration[4.2]
  def up
    change_column :physical_objects, :shrinkage, :decimal, precision: 4, scale: 3
  end
end
