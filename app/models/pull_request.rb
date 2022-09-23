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

	# returns a hash mapping IU barcodes to the corresponding "result" field for that particular PhysicalObject
	def cs_po_map
		map = {}
		response = JSON.parse(caia_soft_response)
		response["results"].each do |p|
			vals = {}
			# "results"=>[{"item"=>"30000136732413", "deny"=>"Y", "istatus"=>"Item in Collection BL cannot circulate to Stop MI - Location default"}]}
			map[p["item"].to_i] = p.except("item")
		end
		map
	end


end
