class RemoveMixedFromPhysicalObjectAddHandAndStencil < ActiveRecord::Migration[4.2]
  def up
    remove_column :physical_objects, :color_bw_color_bw_mixed
    add_column :physical_objects, :color_bw_bw_hand_coloring, :boolean
    add_column :physical_objects, :color_bw_bw_stencil_coloring, :boolean
  end

  def down
    remove_column :physical_objects, :color_bw_bw_stencil_coloring
    remove_column :physical_objects, :color_bw_bw_hand_coloring
    add_column :physical_objects, :color_bw_color_bw_mixed, :boolean
  end
end
