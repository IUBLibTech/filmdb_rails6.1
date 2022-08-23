class CreateCageShelfPhysicalObjects < ActiveRecord::Migration[4.2]
  def up
    if ActiveRecord::Base.connection.table_exists? 'cage_shelf_physical_objects'
      drop_table :cage_shelf_physical_objects
    end
    create_table :cage_shelf_physical_objects do |t|
      t.integer :physical_object_id, limit: 8
      t.integer :cage_shelf_id, limit: 8
      t.datetime :shipped
      t.timestamps
    end

    ####################################################################
    # need to populate the join table with data from both POD and Filmdb
    ####################################################################
    # The POD side - because of MySQL versions on our production servers and Ubuntu no longer supporting those antiquated versions,
    # a bad handshake exception is encountered when trying to run on my local MySQL install (which is version 8, vs the 5.1 and 5.2
    # versions in our production env)
    begin
      puts "Processing POD batch records"
      pod_batches = PodBatch.includes(pod_bins: [:pod_physical_objects]).where(format: 'film').order(:created_at)
      po_count = pod_batches.collect{|b| b.pod_bins.collect{|bin| bin.pod_physical_objects.collect{|p| p.mdpi_barcode}}}.flatten.size
      c = 1
      pod_batches.each_with_index do |b, i|
        puts "Processing Batch #{i + 1} of #{pod_batches.size}"
        batch_iden = b.identifier
        pod_physical_objects = b.pod_bins.first.pod_physical_objects
        pod_physical_objects.each do |p|
          puts "#{c} of #{po_count} physical objects processed"
          c += 1
          mdpi_barcode = p.mdpi_barcode
          po = PhysicalObject.where(mdpi_barcode: mdpi_barcode).first
          raise "Found POD po barcode that isn't in Filmdb: #{mdpi_barcode}" if po.nil?
          shelf = CageShelf.where(identifier: batch_iden).first
          raise "Found POD bin identifier that wasn't in Filmdb: #{batch_iden}" if shelf.nil?
          CageShelfPhysicalObject.new(physical_object_id: po.id, cage_shelf_id: shelf.id, shipped: b.created_at).save!
          # set the 'current' cage shelf on the physical object
          po.update!(cage_shelf_id: shelf.id)
        end
      end
    rescue => e
      raise e.message unless (Socket.gethostname == 'andrew-Latitude-5590')
    end

    # Filmdb side
    cages = Cage.where(shipped: false)
    cages.each_with_index do |cage, i|
      cage.cage_shelves.each do |cs|
        puts "Processing #{i} of #{cages.size} Cages"
        cs.physical_objects.each do |po|
          CageShelfPhysicalObject.new(physical_object_id: po.id, cage_shelf_id: cs.id).save!
        end
      end
    end
  end

  def down
    drop_table :cage_shelf_physical_objects
  end
end
