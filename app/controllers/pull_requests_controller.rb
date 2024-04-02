class PullRequestsController < ApplicationController

	def index
		@page = (params[:page].nil? ? 1 : params[:page].to_i)
		@count = PullRequest.all.size
		@pull_requests = PullRequest.order("id desc").offset((@page - 1) * PullRequest.per_page).limit(PullRequest.per_page)
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
