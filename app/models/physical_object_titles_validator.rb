class PhysicalObjectTitlesValidator < ActiveModel::EachValidator

	def validate_each(record, attribute, value)
		# EquipmentTechnology physical objects do not have titles, everything else must have at least 1 title
		if (record.actable.class == EquipmentTechnology and value.size > 0) || (record.actable.class != EquipmentTechnology && value.size == 0)
			record.errors.add(attribute, options[:message] || "must have at least one title assigned")
		end
	end

end