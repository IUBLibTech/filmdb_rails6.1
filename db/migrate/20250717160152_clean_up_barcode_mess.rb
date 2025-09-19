class CleanUpBarcodeMess < ActiveRecord::Migration[8.0]
  PO_IDS_TO_DELETE = [103150, 103149, 151420]

  # pairs of [<iu_barcode>, <physical object id to remove from>]
  OLD_BARCODES_TO_REMOVE = [
    [30000068459639, 18331],
    [30000157620760, 171322],
    [30000160358390, 175864],
    [30000136613639, 108195],
    [30000157719174, 152237],
    [30000157578752, 165170],
    [30000160200501, 116908],
    [30000160200998, 31834],
    [30000160201848, 115574]
  ]

  def up
    PhysicalObject.transaction do
      PO_IDS_TO_DELETE.each do |id|
        PhysicalObject.find(id).remove_all_trace_fom_db
      end
      OLD_BARCODES_TO_REMOVE.each_with_index do |pair, index|
        puts "Processing row #{index+1}"
        PhysicalObject.remove_old_bc(pair[0], pair[1])
      end
    end
  end

  def down
    # there is no coming back from this! Get it right before running it in production.
  end


end
