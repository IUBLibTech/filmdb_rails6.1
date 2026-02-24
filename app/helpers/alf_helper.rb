# A helper class for interacting with ALF's storage software, CaiaSoft. This module has methods for sending pull requests
# and querying item locations/statuses. See the CaiaSoft documentation at https://portal.caiasoft.com/apiguide.php
#
# It's important to note that any call to CaiaSofts itemloc or itemloclist API will also result in the CaiaSoftItemLoc object
# (for each PhysicalObject in the call) being created/updated. This is done as a side effect so that PhysicalObjects can be
# up to date with a single call to CS, as they move through multiple actions in Filmdb.
#
# Equally important is that when cs_itemloclist is called with an array of PhysicalObjects, a global variable @itemloclist
# is created from the JSON response to avoid repetitious code. There are convenience methods for extracting fields from
# the response which access that object. Those methods will raise an exception if the cs_itemloclist call has not been made.
module AlfHelper
	include CaiaSoftStatusHelper
	require 'net/scp'
	require 'net/sftp'
	require 'net/http'
	require 'json'
	require 'uri'
	require 'open3'


	# CaiaSoft itemloclist restricts to a max of 500 items for the API CALL
	ITEMLOCLIST_MAX = 500

	# 4th field after AL/MI is patron id, not email address, try to figure out which field is email address and use the IULMIA account that Andy monitors
	PULL_LINE_MDPI = "\"REQI\",\":IU_BARCODE\",\"IULMIA – MDPI\",\":TITLE\",\"AM\",\"AM\",\"\",\"\",\":EMAIL_ADDRESS\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"PHY\""
	PULL_LINE_WELLS = "\"REQI\",\":IU_BARCODE\",\"IULMIA – MDPI\",\":TITLE\",\"MI\",\"MI\",\"\",\"\",\":EMAIL_ADDRESS\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"PHY\""
	ALF = "ALF"
	WELLS_052 = "Wells"

	ALF_STOP = "AM"
	WELLS_STOP = "MI"
	DO_NOT_DELIVER = "TE"

	CURL_COMMAND = "curl -X POST -H '$API_KEY_NAME:$API_KEY' -H 'Content-Type: application/json' -d '$REQUEST' $CS_ENDPOINT"


	### The statuses that Filmdb cares about ####
	# CAIASOFT_STATUSES = [
	# 	RESTRICTED_API_ACCESS, NOT_FOUND, IN_ACCESSION_PROCESS, DEACCESSIONED, OUT_OF_ALF, IN_ALF,
	# 	IN_QUEUE_PHYSICAL_RETRIEVAL, IN_QUEUE_DEACCESSION
	# ]

	### Equivalency maps CS status to Filmdb Workflow Statuses ###
	# these are not one to one, but rather one to many. For instance NOT_FOUND in caiasoft could mean many things
	# in Filmdb:
	#   * the item hasn't been accessioned in CS but is physically in ALF
	#   * the item hasn't been accessioned in CS but is physically in IULMIA workspace (either Wells 052 or ALF)
	#   * the item has never been sent to ALF and is MISSING in IULMIA workflow
	#   * the item is a freezer item and is either physically in ALF or in IULMIA workspace
	#   * the item is Equipement/Technology and not stored in ALF (ever) - could be in workflow or in OFFSITE storage
	#   * etc
	#
	EQUIVALENCIES = {
		RESTRICTED_API_ACCESS => [], # no correlation to filmdb - if we see this status it means the API key was changed/deleted!!! Contact Adam
		NOT_FOUND => [
			WorkflowStatus::JUST_INVENTORIED_ALF, WorkflowStatus::JUST_INVENTORIED_WELLS, WorkflowStatus::AWAITING_FREEZER,
			WorkflowStatus::IN_FREEZER, WorkflowStatus::IN_STORAGE_AWAITING_INGEST, WorkflowStatus::IN_STORAGE_INGESTED_OFFSITE,
			WorkflowStatus::MISSING, WorkflowStatus::SHIPPED_EXTERNALLY, WorkflowStatus::DEACCESSIONED, WorkflowStatus::IN_WORKFLOW_ALF,
			WorkflowStatus::IN_WORKFLOW_WELLS,
			# somewhere in older workflow it was possible to pull request an item that was never sent to ALF - include this as
			# a valid status when ALF has never ingested the item
			WorkflowStatus::PULL_REQUESTED
		],
		WAITING_ON_INCOMING_ACCESSION_STREAM => [WorkflowStatus::IN_STORAGE_AWAITING_INGEST],
		IN_ACCESSION_PROCESS => [WorkflowStatus::IN_STORAGE_AWAITING_INGEST],
		COMMITTED => [WorkflowStatus::IN_STORAGE_INGESTED],
		DEACCESSIONED => [WorkflowStatus::DEACCESSIONED],
		OUT_OF_ALF => [
			WorkflowStatus::IN_WORKFLOW_WELLS, WorkflowStatus::IN_WORKFLOW_ALF, WorkflowStatus::SHIPPED_EXTERNALLY,
			WorkflowStatus::MISSING, WorkflowStatus::BEST_COPY_MDPI_WELLS, WorkflowStatus::BEST_COPY_WELLS, WorkflowStatus::BEST_COPY_ALF
		],
		PULLED_E_RETRIEVAL => [WorkflowStatus::IN_STORAGE_INGESTED], # FIXME: check if this is correct
		OUT_ON_SHIP_SERVICE => [WorkflowStatus::IN_STORAGE_INGESTED], # FIXME: stands for "Special Handling, Internal & Preservation" - should it be treated like it's still in ALF hands?
		IN_ALF => [WorkflowStatus::IN_STORAGE_INGESTED, WorkflowStatus::QUEUED_FOR_PULL_REQUEST],
		IN_QUEUE_REFILE => [WorkflowStatus::IN_STORAGE_INGESTED],
		IN_QUEUE_PHYSICAL_RETRIEVAL => [WorkflowStatus::PULL_REQUESTED],
		WAITING_ON_RETRIEVAL_QUEUE => [WorkflowStatus::PULL_REQUESTED],
		IN_QUEUE_E_RETRIEVAL => [WorkflowStatus::IN_STORAGE_INGESTED],
		IN_QUEUE_SHIP_SERVICE => [WorkflowStatus::IN_STORAGE_INGESTED], # FIXME: check in relation to OUT_ON_SHIP_SERVICE
		IN_QUEUE_DEACCESSION => [WorkflowStatus::DEACCESSIONED]
	}

	ALF_TO_FDB_STORAGE_LOCATIONS = {
		IN_ALF => "In Storage",
		NOT_FOUND => "Not Ingested in ALF",
		OUT_OF_ALF => "Delivered to IULMIA",
		IN_QUEUE_PHYSICAL_RETRIEVAL => "Pull Requested",
	}

	# Compares a CaiaSoft status to a Filmdb WorkflowStatus (or WorkflowStatus.status_name) to see if they are functionally
	# equivalent from Filmdb's perspective.
	def self.equivalent_statuses?(alf_status, filmdb_status)
		filmdb_status = filmdb_status.status_name if filmdb_status.is_a? WorkflowStatus
		raise "#{alf_status.chars} is not an ALF status!" unless EQUIVALENCIES.keys.include?(alf_status)
		raise "#{filmdb_status} is not a valid Filmdb WorkflowStatus!" unless WorkflowStatus::ALL_STATUSES.include?(filmdb_status)
		possible = EQUIVALENCIES[alf_status]
		raise "#{alf_status} is not a known status..." if possible.nil?
		possible.include?(filmdb_status)
	end

	# this method is responsible for generating and uploading the pull request to ALF's inventory system, CaiaSoft.
	# See "API Return" section of https://portal.caiasoft.com/apiguide.php?serv=restapi&rec=3&oper=circrequests
	# for information about how the requests is formed and the return results.
	def push_pull_request(physical_objects, user)
		# transaction in case anything goes wrong while writing the upload file and saving the PullRequest object
		# see #generate_upload_file for details
		if physical_objects.length > 0
			# curl call to caiasoft, creates @pr from the response
			result = cs_upload_curl(physical_objects, user)
			# Make sure the curl process exited successfully and if yes, parse the result
			exit_status = $?.exitstatus
			if exit_status == 0
				response = JSON.parse(result)
				# pull requests from non-prod environments have their stop code set to DO_NOT_DELIVER which denies the
				# pull request, however, success is still true.
				if response["success"] == true
					@pr.caia_soft_upload_success = true
					@pr.caia_soft_response = result
					@pr.save!
					@pr.physical_objects.each do |p|
						# need to check the deby status of each PO to see if its workflow status should be updated to pull requested
						# pull requests from non-prod environments will have deny = "Y"
						deny = field_from_pull_request_response(response, "deny", p.iu_barcode)
						if deny && deny == "N"
							ws = WorkflowStatus.build_workflow_status(WorkflowStatus::PULL_REQUESTED, p)
							p.workflow_statuses << ws
							p.current_workflow_status = ws
							p.save!
						end
					end
				else
					@pr.caia_soft_upload_success = false
					@pr.caia_soft_response = result
					@pr.save!
				end
			else
				raise "CURL execution failed with exit code: #{exit_status}"
			end
		end
	end

	# def alf_storage_readable(alf_status)
	# 	match = ALF_TO_FDB_STORAGE_LOCATIONS[alf_status]
	# 	return alf_status if match.nil?
	# 	return match
	# end


	# used for pull requests, this utilizes system curl command to send a JSON payload to CaiaSoft's
	# API at .../api/circrequests/v1
	# See https://portal.caiasoft.com/apiguide.php?serv=restapi&rec=3&oper=circrequests for information about the API
	def cs_upload_curl(pos, user)
		url = URI(cs_circrequest_path)
		key_name = cs_api_key_name
		key = cs_api_key
		payload = cs_pull_request_json_payload(pos, user)
		payload_file = write_payload_to_file(payload, user)
		response = `curl -X POST #{url} -H #{key_name}:#{key} -d @#{payload_file}`
		File.delete(payload_file)
		response
	end

	# using ruby's built in Net::HTTP libraries, calls CaiaSoft's API at .../api/itemloc/v1/<barcode> to get information
	# about the location and status of the specified Physical Object.
	# See https://portal.caiasoft.com/apiguide.php?serv=restapi&rec=1&oper=itemloc for information about the API call
	def cs_itemloc(barcode, po=nil)
		uri = URI(cs_itemloc_path(barcode))
		key_name = cs_api_key_name
		key = cs_api_key

		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true

		req = Net::HTTP::Get.new(uri)
		req[key_name] = key
		response = http.request(req)
		json = JSON.parse(response.body)
		save_itemloc(json["item"].first)
		json
	end

	# using the system's cURL command, calls CaiaSoft's API at ../api/itemloc/v1/<barcode> to get information about the
	# location and status of the specified Physical Object. See https://portal.caiasoft.com/apiguide.php?serv=restapi&rec=1&oper=itemloc
	# for information about the API call
	# def cs_itemloc_curl(barcode)
	# 	url = URI(cs_itemloc_path(barcode))
	# 	key_name = cs_api_key_name
	# 	key = cs_api_key
	# 	`curl #{url} -H #{key_name}:#{key}`
	# end

	# uses the system's cURL command to call CaoaSoft's API at .../api/itemloclist/api to get information about the array
	# of physical objects. See https://portal.caiasoft.com/apiguide.php?serv=restapi&rec=3&oper=itemloclist for information
	# about the API call
	def cs_itemloclist(pos, user = nil)
		# user is possible to be nil as a convenience to not have to type out User.get_current_user_object whenever
		# this method is called. This method STILL needs a user to make the call because of CaiaSoft requirements
		user = User.current_user_object if user.nil?

		# because User.current_user_object is set from the WEBAPP's Session object handling a successful authentication,
		# calling this function from rake tasks or the console will raise an exception. In this case, use the filmdb user
		# account for these calls
		user = User.where(username: "filmdb").first if user.nil?

		url = URI(cs_itemloclist_path)
		key_name = cs_api_key_name
		key = cs_api_key
		payload = cs_itemloclist_json_payload(pos)
		payload_file = write_payload_to_file(payload, user)
		response = `curl -X POST #{url} -H #{key_name}:#{key} -d @#{payload_file}`
		File.delete(payload_file)
		@itemloclist = JSON.parse(response)
		save_itemloclist(pos)
		@itemloclist
	end

	private
	# def generate_pull_file_contents(physical_objects, user)
	# 	str = []
	# 	physical_objects.each do |po|
	# 		if po.storage_location == WorkflowStatus::IN_STORAGE_INGESTED
	# 			str << populate_line(po, user)
	# 		end
	# 	end
	# 	str
	# end

	def populate_line(po, user)
		pl = nil
		if po.active_component_group.deliver_to_alf?
			pl = PULL_LINE_MDPI
		else
			pl = PULL_LINE_WELLS
		end
		pl.gsub(':IU_BARCODE', po.iu_barcode.to_s).gsub(':TITLE', po.titles_text.truncate(20, omission: '')).gsub(':EMAIL_ADDRESS', user.email_address)
	end

	# generates a filename including path of the format <path>/<date>.<process_number>.webform.file where date is the
	# date the function is called and formated yyyymmdd, and process_number is a 0 padded 5 digit number repesenting the
	# (hopefully) id of the PullRequest the file will be associated with
	def gen_file_name
		#"./tmp/#{Date.today.strftime("%Y%m%d")}.#{gen_process_number}.webform.file"
		pre = Rails.application.credentials[:use_caia_soft] ? "alfrequest." : ""
		File.join(Rails.root, 'tmp', "#{pre}#{Date.today.strftime("%Y%m%d")}.#{gen_process_number}.webform.file")
	end

	def gen_process_number
		id = PullRequest.maximum(:id)
		sprintf "%05d", (id.nil? ? 1 : id+1)
	end

	def write_payload_to_file(payload, user)
		filename = File.join(Rails.root, 'tmp', "#{user.username}_pull_request.json")
		if File.exist? filename
			File.delete filename
		end
		File.write(filename, payload)
		filename
	end

	# deletes all files in <Rails.root>/tmp that match the wildcard pattern and are more than exp_days old
	def clear_tmp_files(pattern, exp_days)
		files = Dir[File.join(Rails.root, "tmp", pattern)]
		files.each do |f|
			if File.mtime(f) < exp_days.days.ago
				File.delete(f)
			end
		end
	end

	# generates the JSON payload for upload as the resquest's body for the CaiaSoft inventory system, and creates the
	# global PullRequest object @pr - does NOT save @pr to the database: this should be handled by other code that checks
	# whether the pull request was successfully received by CaiaSoft
	def cs_pull_request_json_payload(pos, user)
		payload = []
		PullRequest.transaction do
			@pr = PullRequest.new(filename: nil, file_contents: nil, requester: user, caia_soft: true)
			pos.each do |p|
				# ALF staff currently (06/2025) only pull ingested and items awaiting ingest. Freezer items are completely
				# managed by IULMIA staff. Use "details" field of the pull request to indicate to ALF staff if the

				# the page displaying the pull request choices would have refreshed each POs caia_soft_item_loc
				# so it's up to date (enough) to use here
				if p.caia_soft_item_loc.status == IN_ALF
					payload << cs_line(p, user)
				elsif p.last_known_storage_location == WorkflowStatus::IN_FREEZER || p.last_known_storage_location == WorkflowStatus::AWAITING_FREEZER
					payload << cs_line(p, user, "IULMIA freezer item - IULMIA staff will retrieve")
				elsif p.last_known_storage_location == WorkflowStatus::IN_STORAGE_AWAITING_INGEST
					payload << cs_line(p, user, "Item should be in IULMIA's awaiting accession area")
				end
				@pr.physical_object_pull_requests.build(physical_object_id: p.id, pull_request_id: @pr.id)
			end
			@pr.json_payload = payload.to_s
		end
		{"requests": payload}.to_json
	end

	def cs_itemloclist_json_payload(pos)
		"{\"items\": [#{pos.collect{|p| p.iu_barcode}.join(",\n")}] }"
	end

	def parse_cs_json_response(result)
		response = JSON.parse(result)
	end

	# Generates a single entry in the JSON payload for CaiaSoft, required fields are:
	# (item) barcode, request_type, and stop
	def cs_line(po, user, details=nil)
		stop = ""
		title = po.titles_text.gsub('"', "").gsub("'", "")
		if Rails.env == "production" || Rails.env == "production_dev"
			stop = po.active_component_group.deliver_to_alf? ? "AM" : "MI"
		else
			stop = DO_NOT_DELIVER
		end
		obj = {"request_type" => "PYR", "barcode" => "#{po.iu_barcode}", "stop" =>  stop, "requestor" => "IULMIA", "patron_id" => "#{user.email_address}",
		 "title" => "#{title}"}
		if details
			obj["details"] = details
		end
		obj
	end

	def cs_endpoint_path
		Rails.application.credentials[:caia_soft_endpoint]
	end
	def cs_circrequest_path
		"#{cs_endpoint_path}#{Rails.application.credentials[:caia_soft_circrequest]}"
	end

	def cs_itemloclist_path
		"#{cs_endpoint_path}#{Rails.application.credentials[:caia_soft_itemloclist]}"
	end
	def cs_itemloc_path(barcode)
		"#{cs_endpoint_path}#{Rails.application.credentials[:caia_soft_itemloc]}/#{barcode}"
	end

	def cs_api_key_name
		Rails.application.credentials[:caia_soft_api_key_name]
	end
	def cs_api_key
		Rails.application.credentials[:caia_soft_api_key]
	end

	# Call this AFTER calling cs_itemloclist to extract a barcode's "status" field from the global attribute @itemloclist
	# which is set when calling cs_itemloclist
	# See https://portal.caiasoft.com/apiguide.php?serv=restapi&rec=3&oper=itemloclist for details on the response.
	# If the barcode passed is not in the response, nil is returned
	def status_from_itemloclist(barcode)
		field_from_itemloclist("status", barcode)
	end

	# Call this AFTER calling cs_itemloclist to extract a barcode's "location" field from the global attribute @itemloclist
	# which is set when calling cs_itemloclist
	def location_from_itemloclist(barcode)
		field_from_itemloclist("location", barcode)
	end

	# Call AFTER calling cs_itemloc to extract the specified field from the global attribute @itemloclist which is set when
	# calling cs_itemloclist
	def field_from_itemloclist(field, barcode)
		raise "You can call this method after first calling AlfHelper#cs_itemloclist" if @itemloclist.nil?
		@itemloclist = JSON.parse(@itemloclist) if @itemloclist.is_a? String
		if @itemloclist["success"] == true
			found = @itemloclist["item"].find{ |p| p["barcode"] == barcode}
			found ? found[field] : nil
		else
			nil
		end
	end

	def item_from_itemloclist(barcode)
		raise "You can call this method after first calling AlfHelper#cs_itemloclist" if @itemloclist.nil?
		@itemloclist = JSON.parse(@itemloclist) if @itemloclist.is_a? String
		if @itemloclist["success"] == true
			 @itemloclist["item"].find{ |p| p["barcode"] == barcode}
		else
			nil
		end
	end

	def field_from_pull_request_response(response, field, barcode)
		response["results"].each do |item|
			if item["item"] == barcode.to_s
				return item[field]
			end
		end
	end

	# compares a Filmdb workflow status name to a CaiaSoft "status" (location) to see if they are functionally equivalent
	def fdb_cs_locs_equivalent?(fdb_location, cs_location)
		AlfHelper.equivalent_statuses?(cs_location, fdb_location)
	end

	# takes a single "item" entry from CaiaSoft's JSON response and either saves an existing record with the current values,
	# or creates a new record if the PO has never been checked against CaiaSoft
	def save_itemloc(item, po=nil)
		bc = item["barcode"]
		po = PhysicalObject.includes(:caia_soft_item_loc).where(iu_barcode: bc.to_i).first if po.nil?
		raise "Could not find a PhysicalObject with barcode: #{bc}!" if po.nil?

		cs = po.caia_soft_item_loc
		if cs.nil?
			cs = CaiaSoftItemLoc.new()
		end
		cs.copy_json(item)
		cs.physical_object = po
		cs.mismatch = !fdb_cs_locs_equivalent?(po.current_workflow_status, cs.status)
		cs.save
	end

	def save_itemloclist(pos)
		pos.each_with_index do |p|
			save_itemloc(item_from_itemloclist(p.iu_barcode), p) unless [30000160219865, 30000165999677].include?(p.iu_barcode)
		end
	end

end
