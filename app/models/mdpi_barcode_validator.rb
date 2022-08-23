class MdpiBarcodeValidator < ActiveModel::EachValidator

	def validate_each(record, attribute, value)
		unless value.blank?
			assigned = ApplicationHelper.mdpi_barcode_assigned?(value)
			if !ApplicationHelper.valid_barcode?(value, true)
				record.errors.add(attribute, options[:message] || "is not valid.")
			elsif assigned && (assigned.is_a?(CageShelf) && assigned != record)
				record.errors.add(attribute, option[:message] || error_message_link(assigned))
			# the record is a base physical object and not a specific type (cage packing does this)
			elsif assigned && assigned.is_a?(PhysicalObject) && !record.class.method_defined?(:acting_as) && record != assigned
				record.errors.add(attribute, options[:message] || error_message_link(assigned))
			elsif assigned && assigned.is_a?(PhysicalObject) && record.class.method_defined?(:acting_as) && record.acting_as != assigned
				record.errors.add(attribute, options[:message] || error_message_link(assigned))
			else
				true
			end
		end
	end

	private
		def error_message_link(assigned)
			"#{assigned.mdpi_barcode} has already been assigned to a #{assigned.class.to_s.titleize}"
		end
end
