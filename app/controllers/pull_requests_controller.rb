class PullRequestsController < ApplicationController

	def index
		@pull_requests = PullRequest.all
	end

	def show
		@pull_request = PullRequest.find(params[:id])
		physical_objects = @pull_request.physical_objects
		@ingested = []
		@not_ingested = []
		physical_objects.each do |p|
			if p.storage_location == WorkflowStatus::IN_STORAGE_INGESTED
				@ingested << p
			else
				@not_ingested << p
			end
		end
	end

end
