class PodPush < ApplicationRecord
	belongs_to :cage

	scope :last_pushes, -> {
		cage_id_hash = PodPush.joins(:cage).group(:cage_id).maximum(:id)
		ids = cage_id_hash.values
		where(id: ids).order("cage_id DESC")
	}

	def result_as_hash
		if result
			JSON.parse result
		else
			{}
		end
	end
end
