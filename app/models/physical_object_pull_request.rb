class PhysicalObjectPullRequest < ApplicationRecord
	belongs_to :pull_request
	belongs_to :physical_object
end
