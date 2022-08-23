class RemoveShippedFromCageShelfPhysicalObject < ActiveRecord::Migration[4.2]
  def up
    remove_column :cage_shelf_physical_objects, :shipped if column_exists? :cage_shelf_physical_objects, :shipped
    add_column :cage_shelves, :shipped, :datetime unless column_exists? :cage_shelves, :shipped
    add_column :cage_shelves, :returned_date, :datetime unless column_exists? :cage_shelves, :returned_date

    # MySQL version problems and bad handshakes: Ubuntu 18 doesn't support older versions of MySQL so connecting to
    # 5.1/5.5 (our production instances) results in a bad handshake error. Only allow this error on local dev instances
    # as this migration should only be run in the context of a db:drop db:create db:migrate to create a new, unpopulated
    # DB
    begin
      batches = PodBatch.where(format: 'film')
      batches.each_with_index do |b, i|
        puts "Processing Batch #{i + 1 } of #{batches.size}"
        CageShelf.where(identifier: b.identifier).first.update!(shipped: b.created_at)
      end
    rescue => e
      raise e.message unless Socket.gethostname == 'andrew-Latitude-5590'
    end
  end

  def down
    remove_column :cage_shelves, :shipped if column_exists? :cage_shelves, :shipped
    remove_column :cage_shelves, :returned_date if column_exists? :cage_shelves, :returned_date
    add_column :cage_shelf_physical_objects, :shipped, :datetime unless column_exists? :cage_shelf_physical_objects, :shipped
  end
end
