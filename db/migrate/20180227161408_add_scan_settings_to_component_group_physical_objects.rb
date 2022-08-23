class AddScanSettingsToComponentGroupPhysicalObjects < ActiveRecord::Migration[4.2]
  def change
    # # move scan settings to the join table
    add_column :component_group_physical_objects, :scan_resolution, :string
    add_column :component_group_physical_objects, :clean, :string
    add_column :component_group_physical_objects, :hand_clean_only, :boolean
    add_column :component_group_physical_objects, :return_on_reel, :boolean
    add_column :component_group_physical_objects, :color_space, :string

    cgs = ComponentGroup.all
    cgs.each_with_index do |cg, index|
      cg.component_group_physical_objects.each do |cgpo|
        puts "Processing CG #{index+1} of #{cgs.size}"
        cgpo.update(scan_resolution: cg.scan_resolution, clean: cg.clean, hand_clean_only: cg.hand_clean_only, return_on_reel: cg.return_on_reel, color_space: cg.color_space)
      end
    end
  end
end
