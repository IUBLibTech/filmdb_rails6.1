class PhysicalObjectCorrectAnsochromeSpelling < ActiveRecord::Migration[4.2]
  def up
    rename_column :physical_objects, :color_bw_color_anscochrome, :color_bw_color_ansochrome
  end

  def down
    rename_column :physical_objects, :color_bw_color_ansochrome, :color_bw_color_anscochrome
  end
end
