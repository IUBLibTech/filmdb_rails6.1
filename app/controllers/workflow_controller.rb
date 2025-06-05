# this controller is responsible for moving physical objects through the workflow. Each workflow state is comprised of
# a pair of of controller actions; one action to display all physical objects currently in that state, and a second action to
# provide ajax functionality to move individual physical objects on to the next workflow state
class WorkflowController < ApplicationController
	include AlfHelper
	include WorkflowHelper
	include ApplicationHelper

	protect_from_forgery with: :null_session, only: [:correct_freezer_loc_post]

	before_action :set_physical_object, only: [:process_receive_from_storage ]
	before_action :set_onsite_pos, only: [:send_for_mold_abatement,
																				:process_send_for_mold_abatement, :receive_from_storage, :process_receive_from_storage,
																				:send_to_freezer, :process_send_to_freezer]
	before_action :set_po, only: [:process_return_to_storage, :process_send_for_mold_abatement, :process_send_to_freezer, :process_mark_missing]


	# action responsible for displaying the page to ship POs to an external vendor/entity
	def show_ship_to_vendor
		@action_header = "Ship"
		@action = ship_to_vendor_url
		render "workflow/ship/show_ship_to_vendor"
	end

	# action responsible for updating the specified POs to be marked as WorkflowStatus::SHIPPED_EXTERNALLY
	def patch_ship_to_vendor
		ids = params[:ids].split(",")
		PhysicalObject.transaction do
			@shipped = []
			ids.each do |id|
				po = PhysicalObject.find(id)
				if po.in_workflow?
					ws = WorkflowStatus.build_workflow_status(WorkflowStatus::SHIPPED_EXTERNALLY, po, false)
					ws.comment = params[:comment]
					po.workflow_statuses << ws
					po.current_workflow_status == ws
					po.save
					@shipped << po.iu_barcode
				end
			end
		end
		flash[:notice] = "#{@shipped.join(" ")} #{@shipped.size > 1 ? "have" : "has"} been Shipped"
		redirect_to show_ship_to_vendor_url, status: 303
	end

	# AJAX call which checks whether a PO can be shipped based on its current workflow location
	def ajax_ship_lookup
		msg = {}
		po = PhysicalObject.where(iu_barcode: params[:barcode]).first
		if po.nil?
			msg["error"] = "Could not find a Physical Object with barcode: #{params[:barcode]}"
			msg["can_ship"] = false
		else
			# POs can only be shipped when IN_WORKFLOW_WELLS IN_WORKFLOW_ALF
			if po.in_workflow?
				msg["can_ship"] = true
				msg["id"] = po.id
				msg["barcode"] = po.iu_barcode
				msg["title"] = po.titles_text
				msg["msg"] = "#{po.iu_barcode} can be Shipped Externally"
			else
				msg["can_ship"] = false
				msg["error"] = "This Physical Object cannot be Shipped because it is not currently In Workflow. Current location: #{po.current_location}"
			end
		end
		render json: msg
	end

	def show_return_from_vendor
		@action_header = "Return Shipped"
		@action = return_from_vendor_url
		render "workflow/ship/show_ship_to_vendor"
	end

	def ajax_return_lookup
		msg = {}
		po = PhysicalObject.where(iu_barcode: params[:barcode]).first
		if po.nil?
			msg["error"] = "Could not find a Physical Object with barcode: #{params[:barcode]}"
			msg["can_return"] = false
		elsif po.current_workflow_status.status_name != WorkflowStatus::SHIPPED_EXTERNALLY
			msg["can_return"] = false
			msg["error"] = "This Physical Object cannot be Returned because it is not currently Shipped Externally. Current location: #{po.current_location}"
		else
			msg["can_return"] = true
			msg["id"] = po.id
			msg["barcode"] = po.iu_barcode
			msg["title"] = po.titles_text
			msg["msg"] = "#{po.iu_barcode} can be Returned from being Shipped Externally"
		end
		render json: msg
	end

	def patch_return_from_vendor
		@returned = []
		ids = params[:ids].split(",")
		PhysicalObject.transaction do
			ids.each do |id|
				po = PhysicalObject.find(id)
				if po.current_workflow_status.status_name == WorkflowStatus::SHIPPED_EXTERNALLY
					ws = WorkflowStatus.build_workflow_status(WorkflowStatus::IN_WORKFLOW_WELLS, po, false)
					ws.comment = params[:comment]
					po.workflow_statuses << ws
					po.current_workflow_status == ws
					po.save
					@returned << po.iu_barcode
				end
			end
		end
		flash[:notice] = "#{@returned.join(" ")} #{@returned.size > 1 ? "have" : "has"} been Returned"
		redirect_to show_return_from_vendor_url, status: 303
	end

	def pull_request
		@physical_objects = PhysicalObject.includes([:titles, :active_component_group, :current_workflow_status]).joins(:current_workflow_status).where("workflow_statuses.status_name = '#{WorkflowStatus::QUEUED_FOR_PULL_REQUEST}'").sort do |a, b|
			if a.current_workflow_status.user.username == b.current_workflow_status.user.username
				a.titles_text <=> b.titles_text
			else
				a.current_workflow_status.user.username <=> b.current_workflow_status.user.username
			end
		end
		@ingested = []
		@not_ingested = []
		@best_copy_alf_count = 0
		@best_copy_wells_count = 0
		@physical_objects.each do |p|
			# FIXME: I no longer think this is necessary - everything in IULMIA's holdings should now be INGESTED
			if p.current_workflow_status.status_name == WorkflowStatus::IN_STORAGE_INGESTED
				@ingested << p
			else
				@not_ingested << p
			end
			if p.active_component_group.group_type == ComponentGroup::BEST_COPY_MDPI_WELLS
				@best_copy_wells_count += 1
			elsif p.active_component_group.group_type == ComponentGroup::BEST_COPY_ALF
				@best_copy_alf_count += 1
			end
		end
	end

	def process_pull_requested
		ids = params[:ids]
		if ids.blank?
			flash[:warning] = 'You did not specify any Physical Objects to pull'
		else
			ids = ids.split(',')
			pos = PhysicalObject.where(id: ids)
			bad_req = []
			begin
				push_pull_request(pos, User.current_user_object)
				if @pr.caia_soft_upload_success
					flash[:notice] = "Storage has been notified to pull #{@pr.automated_pull_physical_objects.size} #{"record".pluralize(@pr.automated_pull_physical_objects.size)}."
				else
					flash[:warning] = "Pull Request Failed at ALF end: #{@pr.caia_soft_response}"
				end
			rescue Exception => e
				puts e.message
				puts e.backtrace.join("\n")
				flash[:warning] = "An error occurred when trying to push the request to the ALF system: #{e.message} (see log files for full details)"
			end
		end
		# the PullRequest object has information about which POs were queued for an ALF team pull, and which POs have to be
		# manually pulled by IULMIA staff (freezer items for instance)
		if @pr
			redirect_to show_pull_request_path(@pr)
		else
			redirect_to :pull_request
		end
	end

	def ajax_cancel_queued_pull_request
		@physical_object = PhysicalObject.where(id: params[:id]).first
		if @physical_object.nil?
			flash.now[:warning] = "Couldn't find physical object with ID #{params[:id]}"
		elsif @physical_object.current_workflow_status.status_name != WorkflowStatus::QUEUED_FOR_PULL_REQUEST
			flash.now[:warning] = "#{@physical_object.iu_barcode} is not currently queued for a pull request"
		else
			PhysicalObject.transaction do
				@physical_object.active_component_group.physical_objects.each do |p|
					p.workflow_statuses << WorkflowStatus.build_workflow_status(p.storage_location, p)
					p.active_component_group = nil
					p.save
				end
			end
			all = @physical_object.active_component_group.physical_objects
			others = all.reject{ |po| po.iu_barcode == @physical_object.iu_barcode}.collect{ |po| po.iu_barcode}.join(', ')
			if all.size > 1
				flash.now[:notice] = "#{@physical_object.iu_barcode} was returned to storage. Additionally, #{others} #{others.size > 2 ? 'were' : 'was'} part of the pull request and have also been returned to storage"
			else
				flash.now[:notice] = "#{@physical_object.iu_barcode} was returned to storage."
			end
		end
		render json: all.collect{ |p| p.iu_barcode }
	end

	# receiving from storage has 3 stages
	# a) rendering the form to scan a barcode (this action handles this)
	# b) ajax processing a scanned barcode to see if it CAN be received, and by the user AT THEIR LOCATION (workflow_controller#new_ajax_receive_iu_barcode)
	# c) receiveing the item and updating it's workflow status if all tests pass (workflow_controller#new_process_receive_from_storage)
	# def receive_from_storage
	# 	@physical_objects = []#PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::PULL_REQUESTED)
	# 	u = User.current_user_object
	# 	if u.worksite_location == 'ALF'
	# 		@alf = true
	# 	else
	# 		@wells = true
	# 	end
	# 	render 'receive_from_storage'
	# end

	# Processes an ajax call with an IU barcode to determine is this item is deliverable, and also is being scanned at
	# the intended delivery location
	def new_ajax_receive_iu_barcode
		@physical_object = PhysicalObject.where(iu_barcode: params[:iu_barcode]).first
		user = User.current_user_object
		if @physical_object.nil?
			@msg = "Could not find a Physical Object with barcode: #{params[:iu_barcode]}"
		elsif @physical_object.current_workflow_status.status_name != WorkflowStatus::PULL_REQUESTED
			@msg = "Cannot receive #{params[:iu_barcode]} because it is not currently at #{WorkflowStatus::PULL_REQUESTED}. Current workflow location: #{@physical_object.current_workflow_status.status_name}"
		else
			# can be received but is it being delivered to the correct place?
			dl = @physical_object.active_component_group.delivery_location
			wl = user.worksite_to_delivery_location
			if dl != wl
				@msg = "Cannot receive #{@physical_object.iu_barcode}. Delivery is intended for #{get_location(dl)} but is being scanned at #{get_location(wl)}."
			end
		end
		render partial: (@msg.blank? ? 'ajax_receive_iu_barcode' : "ajax_receive_error")
	end


	# Processes the POST to receive an item from storage.
	def new_process_receive_from_storage
		user = User.current_user_object
		po = PhysicalObject.where(iu_barcode: params[:physical_object][:iu_barcode]).first
		if po.nil?
			flash[:warning] = "Could not find Physical Object with IU barcode: #{params[:physical_object][:iu_barcode]}."
		elsif po.current_workflow_status.status_name != WorkflowStatus::PULL_REQUESTED
			flash[:warning] = "Cannot receive #{po.iu_barcode} because it is not currently at #{WorkflowStatus::PULL_REQUESTED}. Current workflow location: #{po.current_workflow_status.status_name}"
		else
			dl = po.active_component_group.delivery_location
			wl = user.worksite_to_delivery_location

			# error conditions exist when a PO is being received at a different location that intended: dl != wl
			if (dl != wl)
				flash[:warning] = "Cannot receive #{po.iu_barcode}. Delivery is intended for #{get_location(dl)} but is being canned at #{get_location(wl)}"
			else
				begin
					PhysicalObject.transaction do
						wsn = dl.include?("Wells") ? WorkflowStatus::IN_WORKFLOW_WELLS : WorkflowStatus::IN_WORKFLOW_ALF
						ws = WorkflowStatus.build_workflow_status(wsn, po, false)
						ws.comment = params[:comment]
						po.workflow_statuses << ws
						po.current_workflow_status = ws
						po.save
						flash[:notice] = "#{po.iu_barcode} has been received and is now at #{dl}"
						# no longer notifying Users about the constituents of a pull request
						# others = po.waiting_active_component_group_members?
						# flash[:notice] = "#{po.iu_barcode} workflow status was updated to <b>#{dl}</b>. "
						# if others
						# 	plural = others.size > 1
						# 	others = others.collect{ |p| p.iu_barcode }.join(' ')
						# 	flash[:notice] << "#{others} #{plural ? "are" : "is"} also part of the same Pull Request but #{plural ? "have" : "has"} not yet been received.".html_safe
						# end
					end
				rescue Exception => e
					flash[:warning] = "An error occured while trying to update the Workflow Status. If this problem persists, please contact Carmel."
					puts e.message
					puts e.backtrace.join("\n")
				end
			end
		end
		@physical_objects = []
		redirect_to :receive_from_storage
	end

	# this action handles the beginning of ALF workflow
	# def process_receive_from_storage
	# 	medium = medium_symbol_from_params(params)
	# 	if @physical_object.nil?
	# 		flash[:warning] = "Could not find Physical Object with IU Barcode: #{params[medium][:iu_barcode]}"
	# 	elsif @physical_object.active_component_group.is_iulmia_workflow?
	# 		ws = WorkflowStatus.build_workflow_status(WorkflowStatus::IN_WORKFLOW_ALF, @physical_object)
	# 		@physical_object.workflow_statuses << ws
	# 		@physical_object.save
	# 		flash[:notice] = "#{@physical_object.iu_barcode} has been marked: #{ws.type_and_location}"
	# 	elsif !@physical_object.in_transit_from_storage? && @physical_object.current_workflow_status.status_name != WorkflowStatus::MOLD_ABATEMENT && @physical_object.current_workflow_status.status_name != WorkflowStatus::WELLS_TO_ALF_CONTAINER
	# 		flash[:warning] = "#{@physical_object.iu_barcode} has not been Requested From Storage. It is currently: #{@po.current_workflow_status.type_and_location}"
	# 	elsif @physical_object.current_workflow_status.valid_next_workflow?(params[medium][:workflow]) && @physical_object.active_component_group.deliver_to_wells?
	# 		flash[:warning] = "#{@physical_object.iu_barcode} should have been delivered to Wells 052, Component Group type: #{@physical_object.active_component_group.group_type}"
	# 	elsif @physical_object.footage.blank? && params[medium][:footage].blank? && @physical_object.active_component_group.group_type != ComponentGroup::BEST_COPY_ALF
	# 		flash[:warning] = "You must specify footage for #{@physical_object.iu_barcode}"
	# 	elsif !@physical_object.current_workflow_status.valid_next_workflow?(params[medium][:workflow])
	# 		flash[:warning] = "#{@physical_object.iu_barcode} cannot be moved to status: #{params[medium][:workflow]}. "+
	# 			"It's current status [#{@physical_object.current_workflow_status.type_and_location}] does not allow that."
	# 	else
	# 		ws = WorkflowStatus.build_workflow_status(params[medium][:workflow], @physical_object)
	# 		@physical_object.workflow_statuses << ws
	# 		@physical_object.specific.footage = params[medium][:footage] unless params[medium][:footage].blank?
	# 		@physical_object.specific.can_size = params[medium][:can_size] unless params[medium][:can_size].blank?
	# 		@physical_object.save
	# 		flash[:notice] = "#{@physical_object.iu_barcode} has been marked: #{ws.type_and_location}"
	# 	end
	# 	redirect_to :receive_from_storage
	# end


	# def ajax_alf_receive_iu_barcode
	# 	user = User.current_user_object
	# 	@physical_object = PhysicalObject.where(iu_barcode: params[:iu_barcode]).first
	# 	@error = false
	# 	if @physical_object.nil?
	# 		@msg = "Could not find a record with barcode: #{params[:iu_barcode]}"
	# 	elsif @physical_object.current_workflow_status.status_name != WorkflowStatus::PULL_REQUESTED
	# 		@msg = "Cannot receive #{params[:iu_barcode]} because it is not currently at #{WorkflowStatus::PULL_REQUESTED}. Current workflow location: #{@physical_object.current_workflow_status.status_name}"
	# 	else
	# 		# can be received but is it being delivered to the correct place?
	# 		dl = @physical_object.active_component_group.delivery_location
	# 		if (dl.nil? or dl == ComponentGroup::WORKFLOW_WELLS) && user.worksite_location == "ALF"
	# 			@msg = "This item is intended for delivery to Wells."
	# 			@error = true
	# 		elsif dl == ComponentGroup::WORKFLOW_ALF && user.worksite_location != 'ALF'
	# 			@msg = "This item is intended for delivery to ALF."
	# 			@error = true
	# 		else
	# 			@error = false
	# 		end
	# 	end
	# 	if @error
	# 		render partial: "ajax_receive_error"
	# 	else
	# 		render partial: 'ajax_alf_receive_iu_barcode'
	# 	end
	# end

	# def ajax_wells_receive_iu_barcode
	# 	@physical_object = PhysicalObject.where(iu_barcode: params[:iu_barcode]).first
	# 	if @physical_object.nil?
	# 		@msg = "Could not find physical object with IU barcode: #{params[:iu_barcode]}"
	# 	elsif !@physical_object.in_transit_from_storage? || !@physical_object.current_location == WorkflowStatus::MOLD_ABATEMENT
	# 		@msg = "Error: #{@physical_object.iu_barcode} cannot be received at Wells - its current location is #{@physical_object.current_location}"
	# 	elsif @physical_object.active_component_group.deliver_to_alf?
	# 		@msg = "#{@physical_object.iu_barcode} should have been delivered to ALF. It was pulled for: #{@physical_object.active_component_group.group_type}"
	# 	end
	# 	render partial: 'ajax_wells_receive_iu_barcode'
	# end



	# this action processes received from storage at Wells
	# def process_receive_from_storage_wells
	# 	@physical_object = PhysicalObject.where(iu_barcode: params[:physical_object][:iu_barcode]).first
	# 	if @physical_object.nil?
	# 		flash.now[:warning] = "Could not find Physical Object with barcode #{params[:physical_object][:iu_barcode]}"
	# 	elsif @physical_object.active_component_group.deliver_to_alf?
	# 		flash.now[:warning] = "Error: #{@physical_object.iu_barcode} should have been delivered to ALF. It was pulled for #{@physical_object.active_component_group.group_type}. Please contact Amber/Andrew immediately."
	# 	# elsif !@physical_object.current_workflow_status.valid_next_workflow?(WorkflowStatus::BEST_COPY_MDPI_WELLS)
	# 	# 	flash.now[:warning] = "#{@physical_object.iu_barcode} cannot be received. Its current workflow status is #{@physical_object.current_workflow_status.type_and_location}"
	# 	else
	# 		# ws = WorkflowStatus.build_workflow_status(WorkflowStatus::BEST_COPY_MDPI_WELLS, @physical_object) if @physical_object.active_component_group.is_mdpi_workflow?
	# 		# ws = WorkflowStatus.build_workflow_status(WorkflowStatus::IN_WORKFLOW_WELLS, @physical_object) if @physical_object.active_component_group.is_iulmia_workflow?
	# 		ws = WorkflowStatus.build_workflow_status(WorkflowStatus::IN_WORKFLOW_WELLS, @physical_object, true)
	# 		@physical_object.workflow_statuses << ws
	# 		@physical_object.current_workflow_status == ws
	# 		@physical_object.save
	# 		others = @physical_object.waiting_active_component_group_members?
	# 		if others
	# 			others = others.collect{ |p| p.iu_barcode }.join(', ')
	# 		end
	# 		flash[:notice] = "#{@physical_object.iu_barcode} workflow status was updated to <b>#{WorkflowStatus::IN_WORKFLOW_WELLS}</b> "+
	# 			"#{others ? " #{others} #{others.size > 1 ? "are" : "is"} also part of the same pull request and have not yet been received at Wells" : ''}".html_safe
	# 	end
	# 	@physical_objects = []#PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::PULL_REQUESTED)
	# 	redirect_to :receive_from_storage
	# end

	# def process_receive_from_storage_alf
	# 	@physical_object = PhysicalObject.where(iu_barcode: params[:physical_object][:iu_barcode]).first
	# 	if @physical_object.nil?
	# 		flash.now[:warning] = "Could not find Physical Object with barcode #{params[:physical_object][:iu_barcode]}"
	# 	elsif @physical_object.active_component_group.deliver_to_alf?
	# 		flash.now[:warning] = "Error: #{@physical_object.iu_barcode} should have been delivered to ALF. It was pulled for #{@physical_object.active_component_group.group_type}. Please contact Amber/Andrew immediately."
	# 		# elsif !@physical_object.current_workflow_status.valid_next_workflow?(WorkflowStatus::BEST_COPY_MDPI_WELLS)
	# 		# 	flash.now[:warning] = "#{@physical_object.iu_barcode} cannot be received. Its current workflow status is #{@physical_object.current_workflow_status.type_and_location}"
	# 	else
	# 		# ws = WorkflowStatus.build_workflow_status(WorkflowStatus::BEST_COPY_MDPI_WELLS, @physical_object) if @physical_object.active_component_group.is_mdpi_workflow?
	# 		# ws = WorkflowStatus.build_workflow_status(WorkflowStatus::IN_WORKFLOW_WELLS, @physical_object) if @physical_object.active_component_group.is_iulmia_workflow?
	# 		ws = WorkflowStatus.build_workflow_status(WorkflowStatus::IN_WORKFLOW_WELLS, @physical_object, true)
	# 		@physical_object.workflow_statuses << ws
	# 		@physical_object.current_workflow_status == ws
	# 		@physical_object.save
	# 		others = @physical_object.waiting_active_component_group_members?
	# 		if others
	# 			others = others.collect{ |p| p.iu_barcode }.join(', ')
	# 		end
	# 		flash[:notice] = "#{@physical_object.iu_barcode} workflow status was updated to <b>#{WorkflowStatus::IN_WORKFLOW_WELLS}</b> "+
	# 			"#{others ? " #{others} #{others.size > 1 ? "are" : "is"} also part of the same pull request and have not yet been received at Wells" : ''}".html_safe
	# 	end
	# 	@physical_objects = []#PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::PULL_REQUESTED)
	# 	redirect_to :receive_from_storage
	# end

	def return_to_storage
		@physical_objects = []#PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::JUST_INVENTORIED_WELLS, WorkflowStatus::QUEUED_FOR_PULL_REQUEST, WorkflowStatus::PULL_REQUESTED)
	end

	def ajax_return_to_storage_lookup
		po = PhysicalObject.where(iu_barcode: params[:iu_barcode]).first
		if po.nil?
			@json = {"locations" => [], "warn" => "Could not find a Physical Object with barcode: #{params[:iu_barcode]}"}
		elsif po.current_workflow_status.is_storage_status?
			@json = {"locations" => [], "warn" => "#{params[:iu_barcode]} is already #{po.storage_location}"}
		elsif po.current_workflow_status.missing?
			locations = []
			warn = "#{po.iu_barcode} is currently Missing. If you wish to return it to ALF, continue. If you wish to move it into workflow, use 'Mark Item Found' instead."
			# need to check ad_strip
			if po.medium == "Film" && po.specific.place_in_freezer?
				locations = [WorkflowStatus::IN_FREEZER, WorkflowStatus::AWAITING_FREEZER]
				warn << " This Physical Object also has an AD Strip value of #{po.specific.ad_strip} and can only be stored In Freezer/Awaiting Freezer."
			else
				locations = [WorkflowStatus::IN_STORAGE_INGESTED]
			end
			@json = {"locations" => locations, "warn" => warn}
		elsif po.external?
			@json = {"locations" => [], "warn" => "#{po.iu_barcode} is marked #{WorkflowStatus::SHIPPED_EXTERNALLY}. To return it to storage, it must first be Returned From Vendor."}
		elsif po.current_workflow_status.status_name == WorkflowStatus::PULL_REQUESTED
			@json = {"locations" => [], "warn" => "#{po.iu_barcode} is currently at #{WorkflowStatus::PULL_REQUESTED}. You must Cancel Pull Request to return the item to storage."}
		elsif po.current_workflow_status.in_workflow?
			# check AD Strip value
			if (po.medium == "Film" && po.specific.place_in_freezer?)
				@json = {"locations" => [WorkflowStatus::IN_FREEZER, WorkflowStatus::AWAITING_FREEZER], "warn" => "#{po.iu_barcode} has an AD Strip value of #{po.specific.ad_strip} and can only be stored In Freezer/Awaiting Freezer."}
			else
				@json = {"locations" => [WorkflowStatus::IN_STORAGE_INGESTED], "msg" => "#{po.iu_barcode} will be changed to In Storage (Ingested)"}
			end
		else
			if (po.medium == "Film" && po.specific.place_in_freezer?)
				@json = {"locations" => [WorkflowStatus::IN_FREEZER, WorkflowStatus::AWAITING_FREEZER],
								 "warn" => "#{po.iu_barcode} is in a legacy Workflow Status: #{po.current_workflow_status.status_name}."+
									 " Additionally, it has an AD Strip value of #{po.specific.ad_strip} and can only be stored In Freezer/Awaiting Freezer."}
			else
				@json = {"locations" => [WorkflowStatus::IN_STORAGE_INGESTED],
								 "warn" => "#{po.iu_barcode} is in a legacy Workflow Status: #{po.current_workflow_status.status_name}."}
			end
		end
		render json: @json
	end

	def process_return_to_storage
		@po = PhysicalObject.where(iu_barcode: params[:physical_object][:iu_barcode]).first
		@loc = params[:physical_object][:location]
		@ws = nil
		if @po.nil?
			flash[:warning] = "Could not find a PhysicalObject with barcode: #{params[:physical_object][:iu_barcode]}"
		elsif @po.current_workflow_status.is_storage_status?
			flash[:warning] = "#{params[:physical_object][:iu_barcode]} is already #{@po.current_workflow_status.status_name}."
		elsif @po.current_workflow_status.missing?
			# need to check ad_strip
			if @po.medium == "Film" && @po.specific.place_in_freezer? && !WorkflowStatus.is_freezer_storage?(@loc)
				flash[:warning] = "#{@po.iu_barcode} has an AD Strip value of #{@po.specific.ad_strip} and could not be returned to #{@loc}."
			else
				@ws = WorkflowStatus.build_workflow_status(@loc, @po, false)
				flash[:notice] = "#{@po.iu_barcode} was returned to #{@loc}"
			end
		elsif @po.external?
			flash[:warning] = "#{@po.iu_barcode} is currently marked #{WorkflowStatus::SHIPPED_EXTERNALLY}. The Physical Object must first be Returned From Vendor before it can be Returned to Storage."
		elsif @po.current_workflow_status.status_name == WorkflowStatus::PULL_REQUESTED
			flash[:warning] = "#{@po.iu_barcode} is currently marked #{WorkflowStatus::PULL_REQUESTED}. To return this item to storage, you must Cancel Pull Request."
		elsif @po.current_workflow_status.in_workflow?
			# check AD Strip value
			if @po.medium == "Film" && @po.specific.place_in_freezer? && !WorkflowStatus.is_freezer_storage?(@loc)
				flash[:warning] = "#{@po.iu_barcode} has an AD Strip value of #{@po.specific.ad_strip} and must be returned to In Freezer/Awaiting Freezer."
			else
				@ws = WorkflowStatus.build_workflow_status(@loc, @po, false)
				flash[:notice] = "#{@po.iu_barcode} was returned to #{@loc}"
			end
		else
			# use this for any legacy situations (MDPI, things out of sink, etc). In this case only, ignore workflow status rules
			flash[:notice] = "This Physical Object was in the legacy Workflow Status: '#{@po.current_workflow_status.status_name}' and was returned to #{@loc}"
			@ws = WorkflowStatus.build_workflow_status(@loc, @po, true)
		end
		if @ws
			PhysicalObject.transaction do
				@po.current_workflow_status = @ws
				@po.workflow_statuses << @ws
				@po.active_component_group = nil
				@po.save!
			end
		end
		redirect_to :return_to_storage
	end

	def deaccession
		@physical_object = PhysicalObject.new
	end
	def deaccession_ajax_post
		@physical_object = PhysicalObject.where(iu_barcode: params[:physical_object][:iu_barcode]).first
		if @physical_object
			PhysicalObject.transaction do
				ws = WorkflowStatus.build_workflow_status(WorkflowStatus::DEACCESSIONED, @physical_object, true)
				ws.comment = params[:comment]
				@physical_object.workflow_statuses << ws
				@physical_object.current_workflow_status = ws
				@physical_object.component_group_physical_objects.delete_all
				if @physical_object.save
					flash[:notice] = "#{@physical_object.iu_barcode} has been successfully Deaccessioned"
				else
					flash[:warning] = "Something prevented #{@physical_object.iu_barcode} from being Deaccessioned. If this problem persists, please notify Carmel Curtis."
				end
			end
		else
			@physical_object = PhysicalObject.new
			flash[:warning] = "Could not find a Physical Object with barcode: #{params[:physical_object][:iu_barcode]}"
		end
		render 'deaccession', notice: @msg
	end

	def send_for_mold_abatement
	end

	def process_send_for_mold_abatement
		ws = WorkflowStatus.build_workflow_status(WorkflowStatus::MOLD_ABATEMENT, @po)
		@po.workflow_statuses << ws
		@po.save
		flash.now[:notice] = "#{@po.iu_barcode} has been sent to #{WorkflowStatus::MOLD_ABATEMENT}"
		render :send_for_mold_abatement
	end

	def send_to_freezer
	end
	def process_send_to_freezer
		if @po.medium == 'Film'
			ws = WorkflowStatus.build_workflow_status(WorkflowStatus::IN_FREEZER, @po)
			@po.workflow_statuses << ws
			@po.save
			flash.now[:notice] = "#{@po.iu_barcode}'s location has been updated to' #{WorkflowStatus::IN_FREEZER}"
		else
			flash.now[:warning] = "Only Film can be sent to the Freezer. #{@po.iu_barcode} is a #{@po.medium_name}"
		end
		render :send_to_freezer
	end


	def correct_freezer_loc_get

	end
	def correct_freezer_loc_post
		po = PhysicalObject.where(iu_barcode: params[:iu_barcode]).first
    if po.nil?
			flash[:warning] = "Could not find a Physical Object with IU Barcode #{params[:iu_barcode]}"
		else
			PhysicalObject.transaction do
				current = po.current_location
				#active_cg = po.active_component_group
				if po.medium != 'Film'
					flash.now[:warning] = "Only Films can be moved to the Freezer. #{po.iu_barcode} is a #{po.medium_name}"
				else
					po = po.specific
					if po.ad_strip == "2.5" || po.ad_strip == "3.0 (place for freezer)"
						ws = WorkflowStatus.build_workflow_status(params[:location], po, true)
						po.workflow_statuses << ws
						po.current_workflow_status = ws
						po.save
						flash[:notice] = "#{po.iu_barcode} was moved from #{current} to #{ws.status_name}.".html_safe
					else
						flash.now[:warning] = "Only Films with AD Strip value of 2.5 or higher can be moved to the freezer. #{po.iu_barcode} current AD Strip: #{po.ad_strip}"
					end
				end
			end
		end
		render 'correct_freezer_loc_get'
	end

	def mark_missing
		@physical_objects = []#PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::MISSING)
	end

	def process_mark_missing
		if @po.nil?
			flash[:warning] = "Could not find Physical Object with barcode #{params[:physical_object][:iu_barcode]}"
		else
			ws = WorkflowStatus.build_workflow_status(WorkflowStatus::MISSING, @po, true)
			ws.comment = params[:comment]
			@po.workflow_statuses << ws
			@po.active_component_group = nil
			@po.save
			flash.now[:notice] = "#{@po.iu_barcode} has been marked #{WorkflowStatus::MISSING}."
			@physical_objects = []#PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::MISSING)
		end
		render :mark_missing
	end

	def receive_from_external
		@physical_objects = []#PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::SHIPPED_EXTERNALLY)
		@action_text = 'Returned From External'
		@url = '/workflow/ajax/received_external/'
	end

	# when items have been requested from ALF, it's possible that either ALF cannot find them or that someone else has the
	# item checked out already. This page lists all items in transit from storage and provides links to either cancel the
	# pull request (which puts the item back in storage), or to requeue the item so that it appears on the "Request Pull From Storage" page
	def cancel_after_pull_request
		@physical_objects = PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::PULL_REQUESTED)
		# @physical_objects =
		# 	PhysicalObject.joins("INNER JOIN workflow_statuses on physical_objects.id = workflow_statuses.physical_object_id")
		# 								.where("physical_objects.current_workflow_status_id = workflow_statuses.id AND status_name = 'Queued for Pull Request'")
	end

	def process_cancel_after_pull_request
		@physical_object = PhysicalObject.find(params[:id])
		if @physical_object.current_workflow_status.status_name != WorkflowStatus::PULL_REQUESTED
			flash.now[:warning] = "Physical Object #{@physical_object.iu_barcode} cannot be cancelled from a pull request. It's current status is: #{@physical_object.current_workflow_status.status_name}"
		else
			if @physical_object.same_active_component_group_members?
				flash[:notice] = "#{@physical_object.iu_barcode} was returned to storage [#{@physical_object.storage_location}] but belongs to a component group with other physical objects: "+
					"#{@physical_object.active_component_group.physical_objects.select{|p| p.iu_barcode != @physical_object.iu_barcode}.collect{|p| p.iu_barcode }.join(', ')}. They are still in active workflow."
			else
				flash[:notice] = "#{@physical_object.iu_barcode} was marked returned to storage [#{@physical_object.storage_location}]"
			end
			ws = WorkflowStatus.build_workflow_status(@physical_object.storage_location, @physical_object)
			ws.notes = 'Pull request cancelled after requested (most likely ALF reported the item missing or already checked out)'
			@physical_object.workflow_statuses << ws
			@physical_object.save
		end
		redirect_to cancel_after_pull_request_path
	end

	def process_requeue_after_pull_request
		@physical_object = PhysicalObject.find(params[:id])
		if @physical_object.current_workflow_status.status_name != WorkflowStatus::PULL_REQUESTED
			flash.now[:warning] = "Physical Object #{@physical_object.iu_barcode} cannot be cancelled from a pull request. It's current status is: #{@physical_object.current_workflow_status.status_name}"
		else
			ws = WorkflowStatus.build_workflow_status(WorkflowStatus::QUEUED_FOR_PULL_REQUEST, @physical_object, true)
			ws.notes = "#{@physical_object.iu_barcode} was requeued for pull request (most likely ALF reported the item missing or already checked out)"
			@physical_object.workflow_statuses << ws
			@physical_object.save
			if @physical_object.waiting_active_component_group_members?
				flash[:notice] = "#{@physical_object.iu_barcode} was marked #{@physical_object.current_workflow_status.status_name} but belongs to a component group with other physical objects: "+
					"#{@physical_object.active_component_group.physical_objects.select{|p| p.iu_barcode != self.iu_barcode}.join(', ')}. They are still in active workflow."
			else
				flash[:notice] = "#{@physical_object.iu_barcode} was marked #{@physical_object.current_workflow_status.status_name}"
			end
		end
		redirect_to cancel_after_pull_request_path
	end


	def best_copy_selection
		@physical_objects = []
	end

	def ajax_best_copy_selection_barcode
		bc = params[:iu_barcode]
		@cg = nil
		@physical_object = PhysicalObject.where(iu_barcode: bc).first
		if @physical_object.nil?
			@msg = "Could not find Physical Object with IU Barcode: #{parms[:iu_barcode]}"
			render partial: 'ajax_best_copy_selection_error'
		else
			@cg = @physical_object.active_component_group
			if @cg.nil?
				@msg = "Physical Object #{params[:iu_barcode]} is not in active workflow. It currently should be #{@physical_object.current_workflow_status.type_and_location}"
				render partial: 'ajax_best_copy_selection_error'
			elsif !ComponentGroup::BEST_COPY_TYPES.include?(@cg.group_type)
				@msg = "Physical Object #{params[:iu_barcode]}'s current active component group is not Best Copy. It is: #{@physical_object.active_component_group.group_type}'"
				render partial: 'ajax_best_copy_selection_error'
			else
				redirect_to title_component_group_best_copy_selection_path(@cg.title, @cg)
			end
		end
	end

	def old_best_copy_selection_update
		@component_group = ComponentGroup.find(params[:component_group][:id])
		po_ids = params[:pos].split(',').collect { |p| p.to_i }
		@pos = PhysicalObject.where(id: po_ids)
		@cg_pos = []
		@returned = []
		if @pos.size > 0
			ComponentGroup.transaction do
				@new_cg = ComponentGroup.new(title_id: @component_group.title_id, group_type: 'Reformatting (MDPI)', group_summary: '* Created from Best Copy Selection *')
				if params['4k']
					@new_cg.scan_resolution = '4k'
				else
					@new_cg.scan_resolution = '2k'
				end
				@new_cg.color_space = params[:component_group][:color_space]
				@new_cg.clean = params[:component_group][:clean]
				@new_cg.return_on_reel = params[:component_group][:return_on_reel]
				@new_cg.save!
			end
			if @new_cg.persisted?
				@pos.each do |p|
					@cg_pos << p
					ComponentGroupPhysicalObject.new(physical_object_id: p.id, component_group_id: @new_cg.id).save!
					p.active_component_group = @new_cg
					p.workflow_statuses << WorkflowStatus.build_workflow_status(
						(@component_group.group_type == ComponentGroup::BEST_COPY_MDPI_WELLS ? WorkflowStatus::WELLS_TO_ALF_CONTAINER : WorkflowStatus::TWO_K_FOUR_K_SHELVES),
						p)
					p.save!
				end
			end
		end
		@component_group.physical_objects.each do |p|
			if !po_ids.include?(p.id)
				@returned << p
				p.workflow_statuses << WorkflowStatus.build_workflow_status(p.storage_location, p)
				p.save!
			end
		end
		@physical_objects = []#PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::::BEST_COPY_ALF)
		render 'best_copy_selection'
	end

	def issues_shelf
		#PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::ISSUES_SHELF)
		@physical_objects = PhysicalObject.includes([:titles, :active_component_group, :current_workflow_status]).joins(:current_workflow_status).where("workflow_statuses.status_name = '#{WorkflowStatus::ISSUES_SHELF}'")
	end

	def ajax_issues_shelf_barcode
		bc = params[:iu_barcode]
		@physical_object = PhysicalObject.where(iu_barcode: bc).first
		if @physical_object.nil?
			@msg = "Could not find Physical Object with IU barcode: #{bc}"
			# we can use ajax_best_copy_selection_error partial because it just renders the msg
			render partial: 'workflow/ajax_best_copy_selection_error'
		elsif @physical_object.current_workflow_status.status_name != WorkflowStatus::ISSUES_SHELF
			@msg = "Physical Object #{bc} is not currently on the Issues Shelf! It is #{@physical_object.current_workflow_status.status_name}"
			render partial: 'workflow/ajax_best_copy_selection_error'
		else
			@others = @physical_object.active_component_group.physical_objects.select{ |p| @physical_object != p }
			render partial: 'workflow/ajax_issues_shelf_barcode'
		end
	end

	def ajax_issues_shelf_update
		@physical_object = PhysicalObject.find(params[:id])
		status_name = params[:physical_object][:current_workflow_status]
		if WorkflowStatus::STATUSES_TO_NEXT_WORKFLOW[WorkflowStatus::ISSUES_SHELF].include?(status_name)
			if params[:physical_object][:updated] == '1'
				ws = WorkflowStatus.build_workflow_status(status_name, @physical_object)
				@physical_object.workflow_statuses << ws
				@physical_object.save
				flash.now[:notice] = "Physical Object #{@physical_object.iu_barcode} updated to #{@physical_object.current_workflow_status.status_name}"
			else
				flash.now[:warning] = "Please update the Physical Objects condition metadata before updating it's workflow location."
			end
		else
			flash.now[:warning] = "Physical Object not updated! Invalid workflow status location: '#{status_name}'"
		end
		@physical_objects = PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::ISSUES_SHELF)
		render 'issues_shelf'
	end

	def cancel_pulled
		@physical_object = PhysicalObject.find(params[:id])
		if @physical_object.active_component_group.physical_objects.size > 0

		else

		end
		render 'workflow/receive_from_storage'
	end
	def re_queue_pulled

	end
	def mark_pulled_missing

	end

	# main page for scanning a barcode to update it's workflow status location
	def update_location
	end
	# ajax call that handles the lookup of the barcode scanned into the above
	def ajax_update_location
		bc = params[:barcode]
		@physical_object = PhysicalObject.where("iu_barcode = #{bc} OR mdpi_barcode = #{bc}").first
		render partial: 'workflow/ajax_update_location'
	end
	#ajax call that handles the updating of the PO based on what was selected from the form submission of #ajax_update_location
	def ajax_update_location_post
		@physical_object = PhysicalObject.where(iu_barcode: params[:barcode]).first
		if @physical_object
			ws = WorkflowStatus.build_workflow_status(params[:location], @physical_object, true)
			@physical_object.workflow_statuses << ws
			@physical_object.save
			flash.now[:notice] = "#{@physical_object.iu_barcode} has been updated to #{@physical_object.current_workflow_status.status_name}"
		else
			flash.now[:warning] = "Could not find Physical Object with barcode #{params[:barcode]}"
		end
		render 'workflow/update_location'
	end

	def return_from_mold_abatement
		@physical_objects = PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::MOLD_ABATEMENT)
	end

	def ajax_mold_abatement_barcode
		@physical_object = PhysicalObject.where(iu_barcode: params[:bc].to_i).first.specific
		render partial: 'workflow/ajax_mold_abatement_barcode'
	end

	def update_return_from_mold_abatement
		@physical_object = PhysicalObject.find(params[:id])

		# FIXME: Need to find a better way to handle form submission from generic Physical Objects and Specific Video/Film/Etc...
		params[:physical_object] = params.delete(:video) if @physical_object.medium == 'Video'
		params[:physical_object] = params.delete(:film) if @physical_object.medium == 'Film'

		s = WorkflowStatus.build_workflow_status(params[:physical_object][:current_workflow_status], @physical_object)
		@physical_object.workflow_statuses << s
		@physical_object.specific.update(mold: params[:physical_object][:mold])
		flash[:notice] = "#{@physical_object.iu_barcode} was updated to #{@physical_object.current_workflow_status.status_name}, with Mold attribute set to: #{@physical_object.specific.mold}"
		redirect_to :return_from_mold_abatement
	end

	# renders the page that accespts a barcode to mark a missing item found
	def show_mark_found
		@physical_object = nil
		@physical_objects = []
		render 'workflow/mark_found/mark_found'
	end

	# Rules about adding a PO to a mark found set start with multiple PO having shared titles.
	# 1) the first *Missing* PO is always accepted
	# 2) Subsequent scans are sent with an array of accepted POs so far. The scanned PO (params[:iu_barcode]) is compared
	# to the already scanned barcode (params[:barcodes]) and the 'candidate' is only accepted if it has at least one title
	# in common with the already scanned POs.
	# 3) If the candidate is not missing, doesn't match and existing PO, or does not share at least one title in common with
	# the titles found by POs in params[:barcodes], the resulting JSON returned will contain an error message along with
	# the success attribute set to false
	def ajax_mark_found_lookup
		# the PO that is trying to be added to the set scanned so far
		candidate = PhysicalObject.where(iu_barcode: params[:iu_barcode]).first
		if candidate.nil?
			@error_msg = "Could not find a PhysicalObject with IU Barcode: #{params[:iu_barcode]}"
		elsif candidate.current_location != WorkflowStatus::MISSING
			@error_msg = "PhysicalObject #{params[:iu_barcode]} is not Missing. It's current location is: #{candidate.current_location}"
		else
			# check to see if the passed barcodes have any ids present yet (it's simply a javascript array sent as a string: "[]" is empty)
			bcs = params[:scan_barcodes].tr('\"[]', '').split(',').map(&:to_i)
			if bcs.length > 0
				# turn it into an array of integers
				# lookup the POs in that set
				@pos = PhysicalObject.includes(:titles, :current_workflow_status).where(iu_barcode: bcs)
				# grab the all Titles for those (we've already calculated that there IS an intersection in previous ajax call)
				# and intersect with the candidate's titles/
				@shared_title_ids = @pos.collect{|p| p.titles.collect{|t| t.id}}.flatten.uniq & candidate.titles.collect{|t| t.id}
				# empty array means no intersection
				unless @shared_title_ids.size > 0
					@error_msg = "#{candidate.iu_barcode} does not share any Titles in common with the already select PhysicalObject(s)."
				end
			else
				# This is the first scan so no need to calculate intersections, candidates Titles are the set
				@shared_title_ids = candidate.titles.collect{|t| t.id}
			end
		end
		render json: {:success => @error_msg.nil?, :msg => "#{@error_msg.nil? ? "" : @error_msg}" }.to_json
	end

	def ajax_load_found_selection_table
		bcs = params[:scan_barcodes].tr('\"[]', '').split(',').map(&:to_i)
		@pos = PhysicalObject.where(iu_barcode: bcs)
		shared_title_ids = @pos.collect{|p| p.titles.collect{|t| t.id}}.flatten.uniq
		@titles = Title.where(id: shared_title_ids)
		render partial: 'workflow/mark_found/ajax_load_found_selection_table'
	end

	def ajax_load_found_cg_table
		ids = params[:ids].tr('\"[]', '').split(',').map(&:to_i)
		@pos = PhysicalObject.where(id: ids)
		@titles = []
		@pos.each do |p|
			if @titles.length == 0
				@titles = p.titles
			else
				@titles = @titles & p.titles
			end
		end
		render partial: 'workflow/mark_found/ajax_load_found_cg_table'
	end

	# responds to a barcode scan on the show_mark_found action and allows user to create a new CG and specify a workflow location.
	def choose_found_workflow
		@physical_object = PhysicalObject.where(iu_barcode: params[:iu_barcode].to_i).first
		if @physical_object.nil?
			@error_msg = "Cannot find a PhysicalObject with IU Barcode: #{params[:iu_barcode]}"
		elsif @physical_object.current_workflow_status.status_name != WorkflowStatus::MISSING
			@error_msg = "PhysicalObject #{params[:iu_barcode]} is not currently <i>Missing</i>. Its current workflow status is #{@physical_object.current_workflow_status.status_name}".html_safe
		else
			@statuses = WorkflowStatus::ALL_STATUSES.sort.collect{ |t| [t, t]}
			@component_group_cv = ControlledVocabulary.component_group_cv
		end
		render partial: 'mark_found_workflow_select'
	end

	def update_mark_found
		@po_returns = []
		@po_injects = []
		# params[:workflow].keys holds PhysicalObject ids which need to be "found"
		# params[:workflow][key] holds either the CG workflow type (ComponentGroup::Workflow_WELLS/ALF) OR the
		# WorkflowStatus::IN_STORAGE_INGESTED and is used to determine delivery destination

		pos = params[:workflow].keys

		# Because each PO can have more than one title and the ComponentGroup is associated with a single title,
		# make sure that any POs that have the same, non-storage destination FOR THE SAME TITLE, end up in the same CG.
		# This hash maps a composite of Title id and destination to the component group created for that destination
		cgs = {}
		ComponentGroup.transaction do
			pos.each do |p|
				po = PhysicalObject.find(p)
				loc = params[:workflow][p] # where this PO is going: either WorkflowStatus::IN_STORAGE_INGESTED or ComponentGroup::WORKFLOW_WELLS/ALF
				if loc == WorkflowStatus::IN_STORAGE_INGESTED
					ws = WorkflowStatus.build_workflow_status(WorkflowStatus::IN_STORAGE_INGESTED, po, true)
					ws.comment = params[:comment]
					po.active_component_group = nil
					po.current_workflow_status = ws
					po.workflow_statuses << ws
					po.save
					@po_returns << po
				else
					# this ridiculousness is necessary to maintain radio button mutual exclusivity at the PO level
					t_id = params["po_title_#{p}"]
					cg = nil
					# see if this PO is in a set for a title, going to the same destination
					if cgs["#{t_id}_#{loc}"]
						cg = cgs["#{t_id}_#{loc}"]
					else
						# create a new CG
						cg = ComponentGroup.new(title_id: t_id.to_i, group_type: loc, group_summary: "CG created by moving a missing PO into 'Workflow'")
						cg.save
						# create the composite key of title_id and delivery location
						cgs["#{t_id}_#{loc}"]
					end
					cg.physical_objects << po
					po.active_component_group = cg
					ws = WorkflowStatus.build_workflow_status(cg.delivery_location == ComponentGroup::WORKFLOW_ALF ? WorkflowStatus::IN_WORKFLOW_ALF : WorkflowStatus::IN_WORKFLOW_WELLS, po, true)
					ws.comment = params[:comment]
					po.workflow_statuses << ws
					po.current_workflow_status = ws
					po.save
					@po_injects << po
				end
			end
		end
		render 'workflow/mark_found/mark_found'
	end

	# def update_mark_found_old
	# 	PhysicalObject.transaction do
	# 		@physical_object = PhysicalObject.joins(:workflow_statuses).find(params[:physical_object][:id])
	# 		if @physical_object.nil?
	# 			@error_msg = "Could not find Physical Object with IU barcode: #{params[:iu_barcode]}"
	# 			render partial: 'mark_found_workflow_select'
	# 		elsif !po_missing?(@physical_object)
	# 			@error_msg = "#{params[:iu_barcode]} is not currently marked missing. It should be at #{@physical_object.current_location}"
	# 			render partial: 'mark_found_workflow_select'
	# 		elsif params[:return_to_storage] == "true"
	# 			ws = WorkflowStatus.build_workflow_status(@physical_object.storage_location, @physical_object)
	# 			@physical_object.workflow_statuses << ws
	# 			@physical_object.current_workflow_status = ws
	# 			@physical_object.save
	# 			flash[:notice] = "#{@physical_object.iu_barcode} was Returned to Storage: #{@physical_object.current_location}"
	# 			redirect_to update_mark_found_path
	# 		elsif params[:return_to_storage] == "false"
	# 			if !params[:title]
	# 				@error_msg = "You must select a Title"
	# 				render partial: 'mark_found_workflow_select'
	# 			else
	# 				@title = Title.find(params[:title])
	# 				@cg = ComponentGroup.new(title_id: @title.id, group_type: params[:group_type])
	# 				@cgpo = ComponentGroupPhysicalObject.new(component_group_id: @cg.id, physical_object_id: @physical_object.id)
	# 				@physical_object.active_component_group = @cg
	# 				# active cg must must be set before creating a new workflow status - the WS uses the reference to active_component_group
	# 				@physical_object.active_component_group = @cg
	# 				@ws = WorkflowStatus.build_workflow_status(params[:status], @physical_object, true)
	# 				@physical_object.workflow_statuses << @ws
	# 				@physical_object.current_workflow_status = @ws
	# 				@cg.component_group_physical_objects << @cgpo
	# 				if params[:group_type] == ComponentGroup::REFORMATTING_MDPI
	# 					@cgpo.scan_resolution = params[:scan_resolution]
	# 					@cgpo.color_space = params[:color_space]
	# 					clean = params[:clean]
	# 					if clean == "Hand clean only"
	# 						@cgpo.hand_clean_only = true
	# 					else
	# 						@cgpo.hand_clean_only = false
	# 						@cgpo.clean = clean
	# 					end
	# 					@cgpo.return_on_reel = params[:return_on_reel]
	# 				end
	# 				@cg.save!
	# 				@ws.save!
	# 				@physical_object.save!
	# 				flash[:notice] = "#{@physical_object.iu_barcode} was added to a #{@cg.group_type} Component Group for Title: #{@title.title_text}. "+
	# 						"It was updated to location #{@ws.status_name}"
	# 				redirect_to update_mark_found_path
	# 			end
	# 		end
	# 	end
	# end

	def ajax_mark_found
		bc = params[:iu_barcode]
		@physical_object = PhysicalObject.joins(:workflow_statuses).where(iu_barcode: bc).first
		if @physical_object.nil?
			@msg = "Could not find Physical Object with IU Barcode #{bc}"
		elsif !po_missing?(@physical_object)
			@msg = "#{bc} is not currently marked as missing. It should be at #{@physical_object.current_location}"
		elsif (@physical_object.active_component_group.nil? && !WorkflowStatus::PULLABLE_STORAGE.include?(@physical_object.previous_location) && @physical_object.previous_location != WorkflowStatus::JUST_INVENTORIED_WELLS && @physical_object.previous_location != WorkflowStatus::JUST_INVENTORIED_ALF)
			@msg = "#{bc} cannot currently be marked Found. It no longer has an active component group and was lost in active workflow. Use 'Return to Storage' instead"
		end
		render partial: 'ajax_return_to_storage'
	end

	def digitization_staging_list
		@physical_objects = PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::TWO_K_FOUR_K_SHELVES)
		respond_to do |format|
			format.csv {send_data pos_to_cvs(@physical_objects), filename: 'digitization_staging.csv' }
    end
	end

	private
	def set_physical_object
		medium = nil
		if params[:film]
			medium = :film
		elsif params[:video]
			medium = :video
		elsif params[:recorded_sound]
			medium = :recorded_sound
		else
			raise "Unsupported Physical Object medium #{params.keys}"
		end
		@physical_object = PhysicalObject.where(iu_barcode: params[medium][:iu_barcode]).first.specific
	end

	def set_onsite_pos
		@physical_objects = []
	end
	def set_po
		@po = PhysicalObject.where(iu_barcode: params[:physical_object][:iu_barcode]).first&.specific
	end

	def po_missing?(po)
		po.current_location == WorkflowStatus::MISSING
	end

	# extracts the "Wells" or "ALF" from WorkflowStatus::IN_WORKFLOW_WELLS/ALF
	def get_location(workflow_status)
		if workflow_status.include?("Wells")
			"Wells"
		elsif workflow_status.include?("ALF")
			"ALF"
		else
			""
		end
	end
end