# this module can be used to take a spreadsheet with values that need to be changed inside the backing database based on
# other values in the spreadsheet and/or directing the reassignment of a given attribute to another within the same
# object
module SpreadsheetUpdaterHelper

  # this method takes an IU Barcode and a hash of attribute/attribute pairs. These pairs should be formatted as
  # :sym_1 => :sym_2 indicating that :sym_1 should be assigned whatever value is currently stored in :sym_2
  # AND THAT :sym_2's value should be set to mil
  def reassign_po_attributes(iu_barcode, attribute_value_pairs={})
    # attributes may resside in the specific class (Film/Video/Sound Recording) vs the base PhysicalObject class so
    # grab the specific class (subclass variables will still pass through to PhysicalObject)
    po = PhysicalObject.where(iu_barcode: iu_barcode).first.specific
    if po.nil?
      raise ActiveRecord::RecordNotFound("Could not find a record with IU Barcode: #{iu_barcode}")
    else
      attribute_value_pairs.keys.each do |key|
        PhysicalObject.transaction do
          val = attribute_value_pairs[key]
          if key.class != Symbol || val.class != Symbol
            raise ArgumentError("Arguments not formatted a :symbol/:symbol pairs")
          else
            v = po[val]
            po[key] = v
            po[val] = nil
            po.save!
          end
        end
      end
    end
  end


end
