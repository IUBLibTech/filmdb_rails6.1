class PhysicalObjectCorrectColorAttributes < ActiveRecord::Migration[4.2]
  def up
    rename_column :physical_objects, :color_bw_bw, :color_bw_bw_black_and_white
    rename_column :physical_objects, :color_bw_color, :color_bw_color_color
  end

  def down
    rename_column :physical_objects, :color_bw_bw_black_and_white, :color_bw_bw
    rename_column :physical_objects, :color_bw_color_color, :color_bw_color
  end
end
