class Collection < ApplicationRecord
	has_many :physical_objects, autosave: true
	belongs_to :unit, autosave: true

	# README!!!
	# current_ownership_and_control attribute notes
	# Because of the limitations of HTML select option elements, and the fact that the choices for this metadata "field"
	# contain bold markup, it was decided to implement these in the UI as radio buttons (with javascript de-select) rather
	# than a select. The value stored in this attribute corresponds to the key to the map defined below:
	CURRENT_OWNERSHIP_AND_CONTROL_MAP ={
		1 => "Donor(s) control <b>none</b> of the copyright(s) in the Donated Materials",
		2 => "Donor(s) control <b>all</b> copyrights in the Donated Materials",
		3 => "Donor(s) control <b>some</b> of the copyrights in the Donated Materials"
	}

	# README!!!
	# transfer_of_ownership attribute notes
	# Because of the limitations of HTML select option elements, and the fact that the choices for this metadata "field" are quite
	# verbose, it was decided to implement these in the UI as radio buttons (with javascript de-select). The value of this
	# attribute maps to the corresponding legal text as defined below.
	TRANSFER_OF_OWNERSHIP_MAP = {
		1 => "Donor(s) irrevocably assign to Indiana University any and all copyrights controlled in the Donated Materials.",
		2 => "Donor(s) retain full ownership of any and all copyrights currently control in the Donated Materials, but grant "+
			"the Libraries a nonexclusive right to authorize all uses of these materials for non-commercial research, scholarly, "+
			"and other educational purposes.",
		3 => "Donor(s) retain full ownership of any and all copyrights currently controlled in the Donated Materials for the "+
			"Donor(s) lifetime(s), but grant the Libraries a nonexclusive right to authorize all uses of these materials for "+
			"non-commercial research, scholarly, and other educational purposes during that time. Donor(s) copyrights in the "+
			"Donated Materials shall transfer to the Trustees of Indiana University following my the Donor(s) death(s).",
		4 => "Donor(s) do not transfer or intend to transfer copyright ownership to Indiana University."
	}


end
