class ServicesController < ActionController::Base
	require 'net/http'
	require 'uri'
	require 'memnon_digiprov_collector'
	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :null_session
	include CagesHelper
	include BasicAuthenticationHelper

	before_action :authenticate, only: [:receive, :mods_from_barcode]

	def receive
		logger.info "Someone has successfully authenticate with Filmdb services#receive: #{request.domain(2)}"
		bc = params[:bin_barcode]
		shelf = CageShelf.where(mdpi_barcode: bc.to_i).first
		if shelf.nil?
			@success = 'FAILURE'
			@reason = "Could not find cage shelf with MDPI Barcode: '#{bc}'"
		elsif !shelf.cage.shipped
			@success = 'FAILURE'
			@reason = "#{bc}'s cage has not been shipped to Memnon yet!"
		else
			begin
				PhysicalObject.transaction do
					shelf.physical_objects.each do |p|
						ws = WorkflowStatus.build_workflow_status(p.storage_location, p)
						p.workflow_statuses << ws
						p.save
					end
					if shelf.cage.all_shelves_returned?
						shelf.cage.update!(shipped: false, ready_to_ship: false, returned: true)
					end
					@success = 'SUCCESS'
					shelf.update!(returned: true, returned_date: DateTime.now)
				end
			rescue Exception => error
				@success = 'FAILURE'
				@reason = 'Unexpected failure in Filmdb updating physical objects to Returned to Storage - Please contact Andrew Albrecht'
				logger.debug $!
			end
			MemnonDigiprovCollector.new.collect_shelf_in_thread(shelf.id)
		end
		data = {success: @success, error: (@reason.nil? ? '' : @reason)}
		render xml: data.to_xml(root: 'filmdbService')
	end


	def show_push_cage_to_pod_xml
		begin
			@cage = Cage.find(params[:cage_id])
			file_path = write_xml(@cage)
			@result = post_multipart(file_path)

			render text: @result.body

			# if parse_result
			# 	render 'services/successul_push_to_pod'
			# else
			# 	@message = "Something failed when exporting #{@cage.identifier} to POD\n#{@result}"
			# end
		rescue => e
			@error = e
			render 'failure'
		end
	end

	# /services/mods/:mdpi_barcode
	# this action responds to requests for mods records based on a PhysicalObject MDPI barcode
	def mods_from_barcode
		begin
			@bc = params[:mdpi_barcode]
			po = PhysicalObject.where(mdpi_barcode: @bc).first
			if po.nil?
				@msg = "Could not find an record with MDPI Barcode: #{@bc}"
			elsif !po.digitized
				@mods_title_id = po.titles.first.id
			else
				# it's possible, although highly unlikely, that a physical object would have more than 1 title association AND
				# have been pulled for digitization more than once through multiple titles. In this case, there is no way to know
				# which title record we need to generate MODS for... Carmel understands this and is okay with this service
				# returning the -first- title's MODS data, of all that were selected for digitization.
				@mods_title_id = po.component_groups.where(group_type: ComponentGroup::REFORMATTING_MDPI).first.title_id
			end
			if @msg
				@builder = Nokogiri::XML::Builder.new do |xml|
					xml.error @msg
				end
				render xml: @builder.to_xml, status: 404
			else
				@title = Title.find(@mods_title_id)
				@builder = Nokogiri::XML::Builder.new do |xml|
					xml.mods( "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance", "xmlns": "http://www.loc.gov/mods/v3", "xsi:schemaLocation": "http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd") do
						xml.titleInfo("usage": "primary") {
							xml.title_ @title.title_text
						}

						# creators
						@title.title_creators.each do |tc|
							xml.name("type": "corporate", "usage": "primary") do
								xml.namePart_ tc.name
								xml.role_ do
									xml.roleTerm("authority": "marcrelator", "type": "code") {
										xml.text "pro"
									}
									xml.roleTerm("authority": "marcrelator", "type": "text") {
										xml.text tc.role
									}
								end
							end
						end

						xml.typeOfResource_ ModsHelper.mods_type_of_resource(@title)

						# keep track of whichever dates for the title are not used in dateIssued or temporal elements
						remaining_dates = @title.title_dates
						xml.originInfo {
							xml.place_ {
								xml.placeTerm_("type": "code", "authority": "marccountry") {
									xml.text "---"
								}
							}
							xml.issuance_ {
								xml.text "monographic"
							}
							date = @title.title_dates.where(date_type: 'Publication Date').first
							date = @title.title_dates.where(date_type: 'TBD').first if date.nil?
							remaining_dates = remaining_dates - [date]
							xml.dateIssued("encoding": "edtf") {
								xml.text(date.nil? ? "unknown/unknown" : date.date_text)
							}
							@title.title_publishers.each do |p|
								xml.publisher_ p.name
							end
						}
						unmapped_languages = []
						@title.physical_objects.collect{|p| p.languages.collect(&:language)}.flatten.uniq.each do |l|
							if ModsHelper.marc_code(l).nil?
								unmapped_languages << l
							else
								xml.language {
									xml.languageTerm_("type":"code", "authority":"iso639-2b") {
										xml.text ModsHelper.marc_code(l)
									}
									xml.languageTerm_("type":"text") {
										xml.text ModsHelper.marc_text(l)
									}
								}
							end
						end
						@title.title_genres.each do |g|
							xml.genre_ g.genre
						end

						xml.physicalDescription { xml.internetMediaType_ "application/octet-stream" }
						xml.abstract_ @title.summary
						xml.note_("type":"general") { xml.text @title.notes } unless @title.notes.blank?
						unmapped_languages.each do |l|
							xml.note_("type":"language") {
								xml.text l
							}
						end
						remaining_dates = remaining_dates.select{|d| d.date_type != "Content Date"}
						remaining_dates.each do |date|
							xml.note_("type":"general") {
								xml.text("#{date.date_type}: #{date.date_text}")
							}
						end
						xml.subject_ {
							xml.topic_ {
								xml.text @title.subject
							}
							@title.title_dates.where(date_type: 'Content Date').each do |d|
								xml.temporal_ {
									xml.text "Content Date: #{d.date_text}"
								}
							end
						}

						xml.relatedItem_("type": "original") {
							xml.physicalDescription {
								formats = @title.physical_objects.collect{|p| p.medium }.uniq
								if formats.include?("Film")
									xml.formAuthority_("authority": "gmd") { xml.text "motion picture"}
									xml.formAuthority_("authority": "marccategory") { xml.text "motion picture"}
									xml.formAuthority_("authority": "marcsmd") { xml.text "film reel"}
								elsif formats.include?('Video')
									xml.formAuthority_("authority": "gmd") { xml.text "video recording"}
									xml.formAuthority_("authority": "marccategory") { xml.text "video recording"}
									xml.formAuthority_("authority": "marcsmd") { xml.text "videoreel"}
								elsif formats.include?("Recorded Sound")
									xml.formAuthority_("authority": "gmd") { xml.text "#{p.medium} recording"}
									xml.formAuthority_("authority": "marccategory") { xml.text "#{p.medium} recording"}
									xml.formAuthority_("authority": "marcsmd") { xml.text "#{p.medium}"}
								else
									raise "Unsupported Format type for MODS record creation: #{formats.join(", ")}"
								end
							}
							xml.physicalDescription {
								xml.extent_ @title.mods_extent(po)
							}
							xml.identier_("type":"local") { xml.text "filmdb:#{@title.id}"}
						}

						xml.recordInfo_ {
							xml.descriptionStandard_ "aarc"
							xml.recordCreationDate_("encoding": "iso8601") { xml.text @title.created_at.iso8601(9) }
							xml.recordChangeDate_("encoding": "iso8601") { xml.text @title.updated_at.iso8601(9) }
							xml.recordOrigin_ {
								xml.text "Converted from FilmDB record to MODS version 3.5 using MARC21slim2MODS3-5.xsl (Revision 1.106 2014/12/19), customized for the Avalon Media System"
							}
							xml.recordIdentifier_("source": "local") { xml.text "filmdb:#{@title.id}" }
						}
					end
				end
				render xml: @builder.to_xml
			end
		rescue => error
			puts error.message
			puts error.backtrace
			msg = "An unexpected error occurred requesting MODS for #{@bc}: #{error.message}. If this problem persists, please contact the Filmdb developer(s)."
			@builder = Nokogiri::XML::Builder.new do |xml|
				xml.error do
					xml.short msg
					xml.msg error.message
					xml.backtrace.join('\n')
				end
			end
			render xml: @builder.to_xml, status: 500
		end
	end

	def test_basic_auth
		uri = URI.parse("https://pod-dev.mdpi.iu.edu/responses/objects/40000000334609/metadata/full")
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		request = Net::HTTP::Get.new(uri.request_uri)
		request.basic_auth(Settings.pod_qc_user, Settings.pod_qc_pass)
		result = http.request(request)
		render text: result.to_yaml
	end

	private
	def post_multipart(file_path)
		uri = URI.parse(Rails.configuration.pod_batch_url)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		request = Net::HTTP::Post.new(uri.path)
		request.basic_auth(Settings.pod_qc_user, Settings.pod_qc_pass)
		request.body = File.open(file_path).read

		# Send the request
		result = http.request(request)
		result
	end

	def parse_result
		@result.status == 200
	end


end
