class UpdateErroneousBestCopyDefaults < ActiveRecord::Migration[4.2]
  def change
    ComponentGroup.where(group_type: 'Best Copy (MDPI)').each do |cg|
	    cg.update(scan_resolution: nil, return_on_reel: nil, color_space: nil)
    end
  end
end
