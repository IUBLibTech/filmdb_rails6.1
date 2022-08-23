module AlfHelper
	require 'net/scp'

	# 4th field after AL/MI is patron id, not email address, try to figure out which field is email address and use the IULMIA account that Andy monitors
	PULL_LINE_MDPI = "\"REQI\",\":IU_BARCODE\",\"IULMIA – MDPI\",\":TITLE\",\"AM\",\"AM\",\"\",\"\",\":EMAIL_ADDRESS\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"PHY\""
	PULL_LINE_WELLS = "\"REQI\",\":IU_BARCODE\",\"IULMIA – MDPI\",\":TITLE\",\"MI\",\"MI\",\"\",\"\",\":EMAIL_ADDRESS\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"PHY\""
	ALF = "ALF"
	WELLS_052 = "Wells"

	ALF_CFG = Rails.configuration.alf

	# this method is responsible for generating and upload the ALF system pull request file
	def push_pull_request(physical_objects, user)
		if physical_objects.length > 0
			upload_request_file(physical_objects, user)
		end
	end

	private
	# generates an array containing lines to be written to the ALF batch ingest file
	def upload_request_file(pos, user)
		file_contents = generate_pull_file_contents(pos, user)
		file_path = gen_file
		logger.info "Pull request file: #{file_path}"
		PullRequest.transaction do
			logger.info "File should contain #{file_contents.size} POs"
			if file_contents.size > 0
				File.write(file_path, file_contents.join("\n"))
				logger.info "#{file_path} created"
			end
			@pr = PullRequest.new(filename: file_path, file_contents: (file_contents.size > 0 ? file_contents.join("\n") : ''), requester: User.current_user_object)
			pos.each do |p|
				@pr.physical_object_pull_requests << PhysicalObjectPullRequest.new(physical_object_id: p.id, pull_request_id: @pr.id)
			end
			if file_contents.size > 0
				success = scp(file_path)
			end
			@pr.save!
			@pr
		end
	end

	# based on the alf.cfg file, uploads the specified file to the correct GFS location based on whether jackrabbit is in use
	# yet AND whether Filmdb is running in dev/test or production ENV
	def scp(file)
		if pull_request_where == "jackrabbit"
			Net::SSH.start(pull_request_host, pull_request_user) do |ssh|
				# when testing, make sure to use cedar['upload_test_dir'] - this is the sftp user account home directory
				# when ready to move into production testing change this to cedar['upload_dir'] - this is the ALF automated ingest directory
				success = ssh.scp.upload!(file, pull_request_upload_dir+'/#{file}')
				raise "Failed to scp file to #{pull_request_where}" unless success
				logger.info "scp.upload! returned #{success}"
				success
			end
		elsif pull_request_where == "cedar"
			Net::SCP.start(pull_request_host, pull_request_user, password: ALF_CFG['cedar_password']) do |scp|
				# when testing, make sure to use alf['upload_test_dir'] - this is the sftp user account home directory
				# when ready to move into production testing change this to alf['upload_dir'] - this is the ALF automated ingest directory
				success = scp.upload!(file, "#{pull_request_upload_dir}")
				raise "Failed to scp file to #{pull_request_where}" unless success
				logger.info "scp.upload! returned #{success}"
				success
			end
		else
			raise "Alf.yml does not have a valid 'where' value defined"
		end
	end

	# determines the correct scp destination based on the contents of alf.yml and the Rails.env Filmdb is running in
	def pull_request_upload_dir
		if pull_request_where == 'jackrabbit'
			Rails.env == "production" ? ALF_CFG['upload_dir'] : ALF_CFG['upload_test_dir']
		elsif pull_request_where == 'cedar'
			Rails.env == "production" ? ALF_CFG['cedar_upload_dir'] : ALF_CFG['cedar_upload_test_dir']
		end
	end
	# determines the correct scp user based on the contents of alf.yml and the Rails.env Filmdb is running in
	def pull_request_user
		pull_request_where == 'jackrabbit' ? ALF_CFG['username'] : ALF_CFG['cedar_username']
	end
	# determines the correct GFS host based on the contents of alf.yml
	def pull_request_host
		pull_request_where == 'jackrabbit' ? ALF_CFG['host'] : ALF_CFG["cedar_host"]
	end
	# a rails console utility for testing user/host/destination
	def pull_request_where
		ALF_CFG["where"]
	end

	def pulling_from?
		"#{pull_request_user}@#{pull_request_host} uploads to #{pull_request_upload_dir}"
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
	def gen_file
		#"./tmp/#{Date.today.strftime("%Y%m%d")}.#{gen_process_number}.webform.file"
		File.join(Rails.root, 'tmp', "#{Date.today.strftime("%Y%m%d")}.#{gen_process_number}.webform.file")
	end

	def gen_process_number
		id = PullRequest.maximum(:id)
		sprintf "%05d", (id.nil? ? 1 : id+1)
	end

end
