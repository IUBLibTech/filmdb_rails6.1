class RenamePhysicalObjectAbcdRoll < ActiveRecord::Migration[4.2]
  def up
    rename_column :physical_objects, :generation_ab_a_roll, :generation_a_roll
    rename_column :physical_objects, :generation_ab_b_roll, :generation_b_roll
    rename_column :physical_objects, :generation_ab_c_roll, :generation_c_roll
    rename_column :physical_objects, :generation_ab_d_roll, :generation_d_roll
  end

  def down
    rename_column :physical_objects, :generation_a_roll, :generation_ab_a_roll
    rename_column :physical_objects, :generation_b_roll, :generation_ab_b_roll
    rename_column :physical_objects, :generation_c_roll, :generation_ab_c_roll
    rename_column :physical_objects, :generation_d_roll, :generation_ab_d_roll
  end
end
