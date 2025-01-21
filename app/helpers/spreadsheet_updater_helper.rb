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
    po = po(iu_barcode).specific
    attribute_value_pairs.keys.each do |key|
      PhysicalObject.transaction do
        val = attribute_value_pairs[key]
        if key.class != Symbol || val.class != Symbol
          raise ArgumentError.new("Arguments not formatted a :symbol/:symbol pairs")
        else
          v = po[val]
          po[key] = v
          po[val] = nil
          po.save!
        end
      end
    end
  end

  # This method takes a PO barcode and migrates existing Ephemera/Ephemera Location metadata on the PO into an
  # AccompanyingDocumentation object associated to the PhysicalObject. It sets ephemera and ephemera_location text to
  # the empty string
  def po_ephemera_to_po_accompanying_documentation(iu_barcode)
    po = po(iu_barcode)
    AccompanyingDocumentation.transaction do
      ac = AccompanyingDocumentation.new(description: po.accompanying_documentation, location: po.accompanying_documentation_location)
      ac.save!
      poac = PhysicalObjectAccompanyingDocumentation.new(physical_object_id: po.id, accompanying_documentation_id: ac.id)
      poac.save!
      po.update!(accompanying_documentation: "", accompanying_documentation_location: "")
    end
  end

  def po_ephemera_to_title_accompanying_documentation(iu_barcode)
    po = po(iu_barcode)
    AccompanyingDocumentation.transaction do
      ac = AccompanyingDocumentation.new(description: po.accompanying_documentation, location: po.accompanying_documentation_location, title_id: po.titles.first.id)
      ac.save!
      po.update!(accompanying_documentation: "", accompanying_documentation_location: "")
    end
  end

  private
  def po(iu_barcode)
    po = PhysicalObject.where(iu_barcode: iu_barcode).first
    if po.nil?
      old = PhysicalObjectOldBarcode.where(iu_barcode: iu_barcode).first
      if old.nil? || old.physical_object.nil?
        raise ActiveRecord::RecordNotFound.new("No Physical Object found with barcode: #{iu_barcode}")
      else
        po = old.physical_object
      end
    end
    po
  end


end
