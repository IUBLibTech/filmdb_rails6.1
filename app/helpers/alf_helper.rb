module AlfHelper
	require 'net/scp'
	require 'net/sftp'
	require 'net/http'
	require 'json'
	require 'uri'
	require 'open3'

	# 4th field after AL/MI is patron id, not email address, try to figure out which field is email address and use the IULMIA account that Andy monitors
	PULL_LINE_MDPI = "\"REQI\",\":IU_BARCODE\",\"IULMIA – MDPI\",\":TITLE\",\"AM\",\"AM\",\"\",\"\",\":EMAIL_ADDRESS\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"PHY\""
	PULL_LINE_WELLS = "\"REQI\",\":IU_BARCODE\",\"IULMIA – MDPI\",\":TITLE\",\"MI\",\"MI\",\"\",\"\",\":EMAIL_ADDRESS\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"PHY\""
	ALF = "ALF"
	WELLS_052 = "Wells"

	ALF_STOP = "AM"
	WELLS_STOP = "MI"

	CURL_COMMAND = "curl -X POST -H '$API_KEY_NAME:$API_KEY' -H 'Content-Type: application/json' -d '$REQUEST' $CS_ENDPOINT"

	# this method is responsible for generating and upload the ALF system pull request file
	#{"success"=>true, "error"=>"", "request_count"=>"1",
	# "results"=>[{"item"=>"30000136732413", "deny"=>"Y", "istatus"=>"Item in Collection BL cannot circulate to Stop MI - Location default"}]}
	#
	def push_pull_request(physical_objects, user)
		# transaction in case anything goes wrong while writing the upload file and saving the PullRequest object
		# see #generate_upload_file for details
		if physical_objects.length > 0
			unless Rails.application.credentials[:use_caia_soft]
				upload_gfa(physical_objects, user)
			else
				# this executes a system curl call which connects to caiasoft, checked the success of the call and creates
				# @pr
				result = cs_upload_curl(physical_objects, user)
				# Make sure the curl process exited successfully and if yes, parse the result
				exit_status = $?.exitstatus
				if exit_status == 0
					response = JSON.parse(result)
					if response["success"] == true
						@pr.caia_soft_upload_success = true
						@pr.caia_soft_response = result
						@pr.save!
						@pr.physical_objects.each do |p|
							ws = WorkflowStatus.build_workflow_status(WorkflowStatus::PULL_REQUESTED, p)
							p.workflow_statuses << ws
							p.current_workflow_status = ws
							p.save!
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
	end

	def upload_gfa(physical_objects, user)
		file = generate_upload_file(physical_objects, user)
		contents = file[:file_contents]
		path = file[:file_path]
		scp_old(path)
		PullRequest.transaction do
			@pr = PullRequest.new(filename: path, file_contents: (contents.size > 0 ? contents.join("\n") : ''), requester: User.current_user_object)
			physical_objects.each do |p|
				ws = WorkflowStatus.build_workflow_status(WorkflowStatus::PULL_REQUESTED, p)
				p.workflow_statuses << ws
				p.save!
				@pr.physical_objects << p
			end
			@pr.save!
		end
	end



	#private
	# Because of infrastructure migration changes, scp is no longer necessary. The app user's home directory has a
	# symlinked directory to the GFA endpoint as well as a non-symlinked "test" directory. This method now simply does a
	# file system move of the file to the symlinked directory (or test dir if not in production)
	def scp(file)
		filename = File.split(file).last
		destination_file = File.join(Dir.home, pull_request_upload_dir, filename)
		File.rename(file, destination_file)
	end

	def scp_old(file)
		Net::SCP.start(Rails.application.credentials[:alf_cedar_host], Rails.application.credentials[:alf_cedar_username], password: Rails.application.credentials[:alf_cedar_password]) do |scp|
			# when testing, make sure to use alf['upload_test_dir'] - this is the sftp user account home directory
			# when ready to move into production testing change this to alf['upload_dir'] - this is the ALF automated ingest directory
			success = scp.upload!(file, "#{pull_request_upload_dir}")
			raise "Failed to scp file to Cedar: #{pull_request_upload_dir}" unless success
			logger.info "scp.upload! returned #{success}"
			success
		end
	end


	# determines the correct scp destination based on the contents of credentials.yml for the Rails.env Filmdb is running in
	# only RAILS_ENV=production and RAILS_ENV=production_dev will upload to the actual directory that GFA monitors
	def pull_request_upload_dir
		(Rails.env == "production" || Rails.env == "production_dev") ?
			Rails.application.credentials[:alf_upload_dir] : Rails.application.credentials[:alf_upload_test_dir]
	end

	def generate_pull_file_contents(physical_objects, user)
		str = []
		physical_objects.each do |po|
			if po.storage_location == WorkflowStatus::IN_STORAGE_INGESTED
				str << populate_line(po, user)
			end
		end
		str
	end

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

	# generates a pull request file for ALF containing the requested Physical Objects. This is the OLD way of uploading FILES
	# to GFA. The furture way (ETA late Oct 2022), uses a POST request with JSON payload to Caiasoft server: see #cs_upload_curl
	def generate_upload_file(pos, user)
		file_contents = generate_pull_file_contents(pos, user)
		file_path = gen_file_name
		if file_contents.size > 0
			File.write(file_path, file_contents.join("\n"))
			logger.info "#{file_path} created"
		end
		{file_path: file_path, file_contents: file_contents}
	end

	# uploads a request payload to the CaiaSoft inventory system ALF uses as a GFA replacement
	# NOTE: This uses standard Ruby Net/Http libs but is REALLY slow - simple request of single PO takes 2+ minutes to
	# complete... See #cs_upload_curl as an alternative
	def cs_upload_libs(pos, user)
		uri = URI(cs_circrequest_path)
		key_name = cs_api_key_name
		key = cs_api_key

		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
		req[key_name] = key
		req.body = cs_json_payload(pos, user)
		res = http.request(req)
	end

	# this uses system curl command to send a JSON payload to the CaiaSoft /api/circrequest/v1 API
	def cs_upload_curl(pos, user)
		url = URI(cs_circrequest_path)
		key_name = cs_api_key_name
		key = cs_api_key
		payload = cs_json_payload(pos, user)
		payload_file = write_payload_to_file(payload, user)
		`curl -X POST #{url} -H #{key_name}:#{key} -d @#{payload_file}`
	end

	def cs_itemloc(barcode)
		uri = URI(cs_itemloc_path(barcode))
		key_name = cs_api_key_name
		key = cs_api_key

		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true

		req = Net::HTTP::Get.new(uri)
		req[key_name] = key
		response = http.request(req)
		response.body
	end

	def cs_itemloc_curl(barcode)
		url = URI(cs_itemloc_path(barcode))
		key_name = cs_api_key_name
		key = cs_api_key
		`curl #{url} -H #{key_name}:#{key}`
	end

	# this method generates a JSON payload based on generated physical objects with "fake" barcodes - they should fail the
	# iu_barcode? validation test and result in a denied pull against the CaiaSoft system
	#
	def test_caiasoft_pull
		user = test_user
		pos = test_pull_pos
		cs_upload_curl(pos, user)
	end

	def test_pull_pos
		pos = []
		apos = PhysicalObject.joins(:titles).where("title_text like ?", "%'%").first
		apos.iu_barcode = 1
		double = PhysicalObject.joins(:titles).where("title_text like ?", "%\"%").first
		double.iu_barcode = 2
		pos << apos
		pos << double
		pos
	end

	def test_user
		user = User.find(2) # dev user (jaalbrec)
	end

	def write_payload_to_file(payload, user)
		filename = File.join(Rails.root, 'tmp', "#{user.username}_pull_request.json")
		if File.exist? filename
			File.delete filename
		end
		File.write(filename, payload)
		filename
	end

	# generates the JSON payload for upload as the resquest's body for the CaiaSoft inventory system, and creates the
	# global PullRequest object @pr - does NOT save @pr to the database: this should be handled by other code that checks
	# whether the pull request was successfully received by CaiaSoft
	def cs_json_payload(pos, user)
		payload = []
		PullRequest.transaction do
			@pr = PullRequest.new(filename: nil, file_contents: nil, requester: user, caia_soft: true)
			pos.each do |p|
				# ALF staff only pull ingested and "normal" storage items. If a PO is in the freezer or awaiting freezer,
				# or in ALF but not yet ingested into GFA/CaiaSoft, IULMIA staff manually pull these items themselves - only send
				# POs where storage location is ingested
				if p.storage_location == WorkflowStatus::IN_STORAGE_INGESTED
					payload << cs_line(p, user)
				end
				# ALL POs (freezer, awaiting, or otherwise) need to belong to the PullRequest even though IULMIA staff
				# manually pull certain items
				@pr.physical_object_pull_requests << PhysicalObjectPullRequest.new(physical_object_id: p.id, pull_request_id: @pr.id)
			end
			@pr.json_payload = payload.to_s
		end
		{"requests": payload}.to_json
	end

	def parse_cs_json_response(result)
		response = JSON.parse(result)
	end

	# Generates a single entry in the JSON payload for CaiaSoft, required fields are:
	# (item) barcode, request_type, and stop
	def cs_line(po, user)
		title = po.titles_text.gsub('"', "").gsub("'", "")
		stop = po.active_component_group.deliver_to_alf? ? "AM" : "MI"
		{"request_type" => "PYR", "barcode" => "#{po.iu_barcode}", "stop" =>  stop, "requestor" => "IULMIA", "patron_id" => "#{user.email_address}",
		 "title" => "#{title}"}
	end

	def cs_endpoint_path
		Rails.application.credentials[:caia_soft_endpoint]
	end
	def cs_circrequest_path
		"#{cs_endpoint_path}/#{Rails.application.credentials[:caia_soft_circrequest]}"
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


end
