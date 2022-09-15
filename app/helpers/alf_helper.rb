module AlfHelper
	require 'net/sftp'

	# 4th field after AL/MI is patron id, not email address, try to figure out which field is email address and use the IULMIA account that Andy monitors
	PULL_LINE_MDPI = "\"REQI\",\":IU_BARCODE\",\"IULMIA – MDPI\",\":TITLE\",\"AM\",\"AM\",\"\",\"\",\":EMAIL_ADDRESS\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"PHY\""
	PULL_LINE_WELLS = "\"REQI\",\":IU_BARCODE\",\"IULMIA – MDPI\",\":TITLE\",\"MI\",\"MI\",\"\",\"\",\":EMAIL_ADDRESS\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"PHY\""
	ALF = "ALF"
	WELLS_052 = "Wells"


	# this method is responsible for generating and upload the ALF system pull request file
	def push_pull_request(physical_objects, user)
		# transaction incase anything goes wrong while writing the upload file and saving the PullRequest object
		# see #generate_upload_file for details
		#PullRequest.transaction do
			if physical_objects.length > 0
				file = generate_upload_file(physical_objects, user)
				debugger
				unless Rails.application.credentials[:use_caia_soft]
					scp(file)
				else
					caia_soft_upload(file)
				end
			end
		#end
	end

	private
	# Because of infrastructure migration changes, scp is no longer necessary. The app user's home directory has a
	# symlinked directory to the GFA endpoint as well as a non-symlinked "test" directory. This method now simply does a
	# file system move of the file to the symlinked directory (or test dir if not in production)
	def scp(file)
		filename = File.split(file).last
		destination_file = File.join(Dir.home, pull_request_upload_dir, filename)
		File.rename(file, destination_file)
	end



	# determines the correct scp destination based on the contents of credentials.yml for the Rails.env Filmdb is running in
	# only RAILS_ENV=production and RAILS_ENV=production_dev will upload to the actual directory that GFA monitors
	def pull_request_upload_dir
		(Rails.env == "production" || Rails.env == "production_dev") ?
			Rails.application.credentials[:alf_upload_dir] : Rails.application.credentials[:alf_upload_test_dir]
	end

	# determines the correct scp user based on the contents of credentials.yml for the Rails.env Filmdb is running in
	# def pull_request_user
	# 	Rails.application.credentials[:alf_username]
	# end
	# # determines the correct GFS host based on the contents of credentials.yml in the Rails.env Filmdb is running in
	# def pull_request_host
	# 	Rails.application.credentials[:alf_host]
	# end
	#
	# def pull_request_password
	# 	Rails.application.credentials[:alf_password]
	# end

	# def pulling_from?
	# 	"#{pull_request_user}@#{pull_request_host} uploads to #{pull_request_upload_dir}"
	# end

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

	# generates a pull request file for ALF containing the requested Physical Objects.
	def generate_upload_file(pos, user)
		file_contents = generate_pull_file_contents(pos, user)
		file_path = gen_file_name
		if file_contents.size > 0
			File.write(file_path, file_contents.join("\n"))
			logger.info "#{file_path} created"
		end
		@pr = PullRequest.new(filename: file_path, file_contents: (file_contents.size > 0 ? file_contents.join("\n") : ''), requester: User.current_user_object)
		pos.each do |p|
			@pr.physical_object_pull_requests << PhysicalObjectPullRequest.new(physical_object_id: p.id, pull_request_id: @pr.id)
		end
		@pr.save!
		@pr
		file_path
	end

	def caia_soft_upload(file)
		url = Rails.application.credentials[:caia_soft_endpoint]
		key_name = Rails.application.credentials[:caia_soft_api_key_name]
		key = Rails.application.credentials[:caia_soft_api_key]

		uri = URI(url)
		request = Net::HTTP::Post.new(uri)
		request[key_name] = key
		request.use_ssl = true
		request.set_form([['upload', File.open(file)]], 'multipart/form-data')
		response = request.request(request)
		debugger
	end

end
