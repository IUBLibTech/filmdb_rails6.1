class IuBarcodeValidator < ActiveModel::EachValidator

	def validate_each(record, attribute, value)
		assigned = ApplicationHelper.iu_barcode_assigned?(value)
		if !ApplicationHelper.valid_barcode?(value)
			record.errors.add(attribute, options[:message] || "is not valid.")
		else
			# check if an existing IN USE barcode is trying to be assigned
			# it's important that the above test checks against PhysicalObject vs PhysicalObject. The 'record' is passed in
			# as it's subtype (Film/Video) and assigned returns the base PhysicalObject since we don't want any PO with that
			# BARCODE
			if assigned && assigned != record.acting_as
				record.errors.add(attribute, options[:message] || error_message_link(assigned))
			else
				# check if the barcode has been previously assigned and is NOT IN USE any longer
				# old barcodes are allowed to be reassigned to the object to which they were originally assigned though
				old = PhysicalObjectOldBarcode.where(iu_barcode: value)
				if old.size > 0
					if !old.collect{|o| o.physical_object_id}.include?(record.acting_as.id)
						record.errors.add(attribute, "#{value} was previously assigned to another Physical Object.")
					end
				end
			end
		end
	end

	private
		def error_message_link(assigned)
			"#{assigned.iu_barcode} has already been assigned to a #{assigned.class.to_s.titleize}"
		end
end
