class PullRequest < ApplicationRecord
	has_many :physical_object_pull_requests
	has_many :physical_objects, through: :physical_object_pull_requests
	belongs_to :requester, class_name: 'User', foreign_key: "created_by_id", autosave: true

	def automated_pull_physical_objects
		autos = []
		physical_objects.each do |p|
			if p.storage_location == WorkflowStatus::IN_STORAGE_INGESTED
				autos << p
			end
		end
		autos
	end

	def manual_pull_physical_objects
		mans = []
		physical_objects.each do |p|
			if p.storage_location != WorkflowStatus::IN_STORAGE_INGESTED
				mans << p
			end
		end
		mans
	end

end
