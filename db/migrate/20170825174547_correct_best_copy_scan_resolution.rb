class CorrectBestCopyScanResolution < ActiveRecord::Migration[4.2]
  def change
    ComponentGroup.where("group_type = 'Best Copy (MDPI)' AND scan_resolution is not null").each do |cg|
      cg.update(scan_resolution: nil)
    end
  end
end
