class MigratePodDigiprov < ActiveRecord::Migration[4.2]
  def change
    pos = PhysicalObject.where(medium: ['Video', 'Recorded Sound']).where("mdpi_barcode is not null")
    size = pos.size
    pos.each_with_index do |p, i|
      puts "Grabbing digiprov #{i+1} of #{size}"
      dpc = MemnonDigiprovCollector.new
      dpc.collect_object(p, nil)
    end
  end
end
