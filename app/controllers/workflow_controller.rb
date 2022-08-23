# this controller is responsible for moving physical objects through the workflow. Each workflow state is comprised of
# a pair of of controller actions; one action to display all physical objects currently in that state, and a second action to
# provide ajax functionality to move individual physical objects on to the next workflow state
class WorkflowController < ApplicationController
	include AlfHelper
	include WorkflowHelper
	include ApplicationHelper

	before_action :set_physical_object, only: [:process_receive_from_storage ]
	before_action :set_onsite_pos, only: [:send_for_mold_abatement,
																				:process_send_for_mold_abatement, :receive_from_storage, :process_receive_from_storage,
																				:send_to_freezer, :process_send_to_freezer]
	before_action :set_po, only: [:process_return_to_storage, :process_send_for_mold_abatement, :process_send_to_freezer, :process_mark_missing]


	def pull_request
		#PhysicalObject.includes(:titles).joins(:active_component_group).where_current_workflow_status_is(nil, nil, false, WorkflowStatus::QUEUED_FOR_PULL_REQUEST)
		#@physical_objects = PhysicalObject.includes([:titles, :active_component_group, :current_workflow_status]).joins(:current_workflow_status).where("workflow_statuses.status_name = '#{WorkflowStatus::QUEUED_FOR_PULL_REQUEST}'").sort_by{ |p| p.titles_text}
		@physical_objects = PhysicalObject.includes([:titles, :active_component_group, :current_workflow_status]).joins(:current_workflow_status).where("workflow_statuses.status_name = '#{WorkflowStatus::QUEUED_FOR_PULL_REQUEST}'").sort do |a, b|
			if a.active_component_group.group_type == b.active_component_group.group_type
				a.titles_text <=> b.titles_text
			else
				ComponentGroup::PULL_REQUEST_GROUP_SORT_ORDER.index(a.active_component_group.group_type) <=> ComponentGroup::PULL_REQUEST_GROUP_SORT_ORDER.index(b.active_component_group.group_type)
			end
		end
		@ingested = []
		@not_ingested = []
		@best_copy_alf_count = 0
		@best_copy_wells_count = 0
		@physical_objects.each do |p|
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
				PhysicalObject.transaction do
					pos.each do |p|
						ws = WorkflowStatus.build_workflow_status(WorkflowStatus::PULL_REQUESTED, p)
						p.workflow_statuses << ws
						p.save!
					end
					@pr = push_pull_request(pos, User.current_user_object)
					flash[:notice] = "Storage has been notified to pull #{@pr.automated_pull_physical_objects.size} records."
				end
			rescue Exception => e
				#logger.error e.message
				#logger.error e.backtrace.join("\n")
				puts e.message
				puts e.backtrace.join("\n")
				flash[:warning] = "An error occurred when trying to push the request to the ALF system: #{e.message} (see log files for full details)"
			end
		end
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

	def receive_from_storage
		@physical_objects = []#PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::PULL_REQUESTED)
		u = User.current_user_object
		if u.worksite_location == 'ALF'
			@alf = true
		else
			@wells = true
		end
	end
	# this action handles the beginning of ALF workflow
	def process_receive_from_storage
		medium = medium_symbol_from_params(params)
		if @physical_object.nil?
			flash[:warning] = "Could not find Physical Object with IU Barcode: #{params[medium][:iu_barcode]}"
		elsif @physical_object.active_component_group.is_iulmia_workflow?
			ws = WorkflowStatus.build_workflow_status(WorkflowStatus::IN_WORKFLOW_ALF, @physical_object)
			@physical_object.workflow_statuses << ws
			@physical_object.save
			flash[:notice] = "#{@physical_object.iu_barcode} has been marked: #{ws.type_and_location}"
		elsif !@physical_object.in_transit_from_storage? && @physical_object.current_workflow_status.status_name != WorkflowStatus::MOLD_ABATEMENT && @physical_object.current_workflow_status.status_name != WorkflowStatus::WELLS_TO_ALF_CONTAINER
			flash[:warning] = "#{@physical_object.iu_barcode} has not been Requested From Storage. It is currently: #{@po.current_workflow_status.type_and_location}"
		elsif @physical_object.current_workflow_status.valid_next_workflow?(params[medium][:workflow]) && @physical_object.active_component_group.deliver_to_wells?
			flash[:warning] = "#{@physical_object.iu_barcode} should have been delivered to Wells 052, Component Group type: #{@physical_object.active_component_group.group_type}"
		elsif @physical_object.footage.blank? && params[medium][:footage].blank? && @physical_object.active_component_group.group_type != ComponentGroup::BEST_COPY_ALF
			flash[:warning] = "You must specify footage for #{@physical_object.iu_barcode}"
		elsif !@physical_object.current_workflow_status.valid_next_workflow?(params[medium][:workflow])
			flash[:warning] = "#{@physical_object.iu_barcode} cannot be moved to status: #{params[medium][:workflow]}. "+
				"It's current status [#{@physical_object.current_workflow_status.type_and_location}] does not allow that."
		else
			ws = WorkflowStatus.build_workflow_status(params[medium][:workflow], @physical_object)
			@physical_object.workflow_statuses << ws
			@physical_object.specific.footage = params[medium][:footage] unless params[medium][:footage].blank?
			@physical_object.specific.can_size = params[medium][:can_size] unless params[medium][:can_size].blank?
			@physical_object.save
			flash[:notice] = "#{@physical_object.iu_barcode} has been marked: #{ws.type_and_location}"
		end
		redirect_to :receive_from_storage
	end

	def process_receive_non_mdpi_alf_from_storage

	end

	def ajax_alf_receive_iu_barcode
		@physical_object = PhysicalObject.where(iu_barcode: params[:iu_barcode]).first.specific
		@cv = ControlledVocabulary.physical_object_cv(@physical_object.medium)
		if @physical_object.nil?
			@msg = "Could not find a record with barcode: #{params[:iu_barcode]}"
		elsif !@physical_object.in_transit_from_storage? && !@physical_object.current_workflow_status.status_name == WorkflowStatus::MOLD_ABATEMENT && !@physical_object.current_workflow_status.status_name == WorkflowStatus::WELLS_TO_ALF_CONTAINER
			@msg = "Error: #{@physical_object.iu_barcode} has not been Requested From Storage. Current Workflow status/location: #{@physical_object.current_workflow_status.type_and_location}"
		elsif @physical_object.active_component_group.is_iulmia_workflow?
			render partial: 'ajax_alf_receive_non_mdpi_iu_barcode'
		else
			render partial: 'ajax_alf_receive_iu_barcode'
		end
	end

	def ajax_wells_receive_iu_barcode
		@physical_object = PhysicalObject.where(iu_barcode: params[:iu_barcode]).first
		if @physical_object.nil?
			@msg = "Could not find physical object with IU barcode: #{params[:iu_barcode]}"
		elsif !@physical_object.in_transit_from_storage? || !@physical_object.current_location == WorkflowStatus::MOLD_ABATEMENT
			@msg = "Error: #{@physical_object.iu_barcode} cannot be received at Wells - its current location is #{@physical_object.current_location}"
		elsif @physical_object.active_component_group.deliver_to_alf?
			@msg = "#{@physical_object.iu_barcode} should have been delivered to ALF. It was pulled for: #{@physical_object.active_component_group.group_type}"
		end
		render partial: 'ajax_wells_receive_iu_barcode'
	end

	# this action processes received from storage at Wells
	def process_receive_from_storage_wells
		@physical_object = PhysicalObject.where(iu_barcode: params[:physical_object][:iu_barcode]).first
		if @physical_object.nil?
			flash.now[:warning] = "Could not find Physical Object with barcode #{params[:physical_object][:iu_barcode]}"
		elsif @physical_object.active_component_group.deliver_to_alf?
			flash.now[:warning] = "Error: #{@physical_object.iu_barcode} should have been delivered to ALF. It was pulled for #{@physical_object.active_component_group.group_type}. Please contact Amber/Andrew immediately."
		elsif !@physical_object.current_workflow_status.valid_next_workflow?(WorkflowStatus::BEST_COPY_MDPI_WELLS)
			flash.now[:warning] = "#{@physical_object.iu_barcode} cannot be received. Its current workflow status is #{@physical_object.current_workflow_status.type_and_location}"
		else
			ws = WorkflowStatus.build_workflow_status(WorkflowStatus::BEST_COPY_MDPI_WELLS, @physical_object) if @physical_object.active_component_group.is_mdpi_workflow?
			ws = WorkflowStatus.build_workflow_status(WorkflowStatus::IN_WORKFLOW_WELLS, @physical_object) if @physical_object.active_component_group.is_iulmia_workflow?
			@physical_object.workflow_statuses << ws
			@physical_object.save
			others = @physical_object.waiting_active_component_group_members?
			if others
				others = others.collect{ |p| p.iu_barcode }.join(', ')
			end
			flash.now[:notice] = "#{@physical_object.iu_barcode} workflow status was updated to <b>#{WorkflowStatus::IN_WORKFLOW_WELLS}</b> "+
				"#{others ? " #{others} are also part of this objects pull request and have not yet been received at Wells" : ''}".html_safe
		end
		@physical_objects = []#PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::PULL_REQUESTED)
		redirect_to :receive_from_storage
	end

	def return_to_storage
		@physical_objects = []#PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::JUST_INVENTORIED_WELLS, WorkflowStatus::QUEUED_FOR_PULL_REQUEST, WorkflowStatus::PULL_REQUESTED)
	end

	def ajax_return_to_storage_lookup
		po = PhysicalObject.where(iu_barcode: params[:iu_barcode]).first
		if po.nil?
			render text: "Error: Could not find Physical Object with IU barcode: #{params[:iu_barcode]}"
		elsif po.current_workflow_status.is_storage_status?
			# no longer preventing PO's from being moved around IN storage
			# render text: "<div class='return_warn'>#{po.iu_barcode} is already in storage</div>".html_safe
			render text: "#{params[:iu_barcode]} Should Be Stored: <b>#{(po.storage_location.blank? ? WorkflowStatus::IN_STORAGE_INGESTED : po.storage_location)}</b>".html_safe
		elsif po.current_location == WorkflowStatus::JUST_INVENTORIED_WELLS || po.current_location == WorkflowStatus::JUST_INVENTORIED_ALF
			render text: "#{params[:iu_barcode]} Should Be Returned to: <b>#{(po.storage_location.blank? ? WorkflowStatus::IN_STORAGE_INGESTED : po.storage_location)}</b>".html_safe
		elsif po.current_workflow_status.missing?
			render text: "<div class='return_warn'>#{po.iu_barcode} should be returned to #{po.storage_location}. However, it was previously marked <i>Missing</i>. "+
					"If you do not wish to return it to storage, use 'Mark Item Found' instead.</div>".html_safe

		# just inventoried PhysicalObjects do not have an active component group (since they've only just been created) so
		# this test MUST occur after the test for current location equaling one of the Just Inventoried locations
		elsif po.active_component_group.nil?
			render text: "<div class='return_warn'>#{po.iu_barcode} does not have an <i>active</i> Component Group. This indicates an error elsewhere. Please contact Carmel!</div>".html_safe
		elsif po.active_component_group.physical_objects.size == 1
			render text: "#{po.iu_barcode} should be returned to #{po.storage_location}."
		elsif po.active_component_group.physical_objects.size > 1
			render text: "<div class='return_warn'>#{params[:iu_barcode]} belongs to a Component Group with other Physical Objects. "+
					"Returning #{params[:iu_barcode]} will remove it from this Component Group. If you wish to continue, the item"+
					" should be returned to #{po.storage_location}.</div>".html_safe
		else
			render text: "An unknown state has been encountered with #{params[:iu_barcode]}. Please contact Carmel."
		end
	end

	def process_return_to_storage
		@po = PhysicalObject.where(iu_barcode: params[:physical_object][:iu_barcode]).first
		w = nil
		if @po.nil?
			flash[:warning] = "Could not find a PhysicalObject with barcode: #{params[:physical_object][:iu_barcode]}"
		elsif @po.current_workflow_status.is_storage_status?
			w = WorkflowStatus.build_workflow_status(params[:physical_object][:location], @po)
			flash[:notice] = "#{@po.iu_barcode} has been relocated in storage from: #{@po.current_location} to #{params[:physical_object][:location]}"
		elsif @po.current_location == WorkflowStatus::JUST_INVENTORIED_WELLS || @po.current_location == WorkflowStatus::JUST_INVENTORIED_ALF
			w = WorkflowStatus.build_workflow_status(params[:physical_object][:location], @po)
			flash[:notice] = "#{@po.iu_barcode}'s location has been updated to #{params[:physical_object][:location]}."
		elsif @po.current_workflow_status.missing?
			w = WorkflowStatus.build_workflow_status(params[:physical_object][:location], @po, true)
			flash[:notice] = "#{@po.iu_barcode}'s location has been updated to #{params[:physical_object][:location]} and is no longer <i>Missing</i>."
		elsif @po.active_component_group.nil?
			flash[:warning] = "#{@po.iu_barcode} does not have an <i>active</i> Component Group. This indicates an error "+
					"elsewhere and the item's location <b>has not</b> been update. Please contact Carmel!"
		elsif @po.active_component_group.physical_objects.size == 1
			w = WorkflowStatus.build_workflow_status(params[:physical_object][:location], @po, true)
			flash[:notice] = "#{@po.iu_barcode}'s location has been updated to #{params[:physical_object][:location]}."
		elsif @po.active_component_group.physical_objects.size > 1
			w = WorkflowStatus.build_workflow_status(params[:physical_object][:location], @po, true)
			@remove = true
			flash[:notice] = "#{@po.iu_barcode}'s location has been updated to #{params[:physical_object][:location]}. "+
					"It has also been removed from it's active Component Group."
		else
			flash[:warning] = "An unknown state has been encountered with returning #{@po.iu_barcode} to storage. "+
					"<b>Nothing has been updated</b>! Please contact Carmel."
		end
		PhysicalObject.transaction do
			unless w.nil?
				@po.current_workflow_status = w
				@po.workflow_statuses << w
				@po.component_group_physical_objects.where(component_group_id: @po.active_component_group).delete_all if @remove
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
				active_cg = po.active_component_group
				if po.medium != 'Film' && (params[:location] == WorkflowStatus::IN_FREEZER || params[:location] == WorkflowStatus::AWAITING_FREEZER)
					flash.now[:warning] = "Only Films can be moved to the Freezer. #{po.iu_barcode} is a #{po.medium_name}"
					break
				end
				ws = WorkflowStatus.build_workflow_status(params[:location], po, true)
				po.workflow_statuses << ws
				po.current_workflow_status = ws
				if !params[:remove].nil?
					if !active_cg.nil?
						ComponentGroupPhysicalObject.where(physical_object_id: po.id, component_group_id: active_cg.id).delete_all
					end
					po.active_component_group = nil
				end
				po.save
				flash[:notice] = "#{po.iu_barcode} was moved from #{current} to #{ws.status_name}.".html_safe
				if !active_cg.nil?
					flash[:notice] = "#{flash[:notice]} Additionally the physical object was <b>#{!params[:remove].nil? ? 'removed' : 'not removed'}</b> from its active component group."
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
		@physical_object.specific.update_attributes(mold: params[:physical_object][:mold])
		flash[:notice] = "#{@physical_object.iu_barcode} was updated to #{@physical_object.current_workflow_status.status_name}, with Mold attribute set to: #{@physical_object.specific.mold}"
		redirect_to :return_from_mold_abatement
	end

	# renders the page that accespts a barcode to mark a missing item found
	def show_mark_found
		@physical_objects = []#PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatus::MISSING)
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
			puts "\n\n\nCould find the PO...\n\n\n"
		elsif @physical_object.current_workflow_status.status_name != WorkflowStatus::MISSING
			@error_msg = "PhysicalObject #{params[:iu_barcode]} is not currently <i>Missing</i>. Its current workflow status is #{@physical_object.current_workflow_status.status_name}".html_safe
			puts "\n\n\nThe PO IS NOT missing...\n\n\n"
		else
			puts "\n\n\nUpdating a missing PO...\n\n\n"
			@statuses = WorkflowStatus::ALL_STATUSES.sort.collect{ |t| [t, t]}
			@component_group_cv = ControlledVocabulary.component_group_cv
		end
		render partial: 'mark_found_workflow_select'
	end

	def update_mark_found
		po_ids = params[:pos].keys #.map(&:to_i)
		@po_returns = []
		@po_injects = []
		po_ids.each do |k|
			if params[:pos][k].keys.first == "inject"
				@po_injects << k
			elsif params[:pos][k].keys.first == "return"
				@po_returns << k
			else
				raise "A PhysicalObject was 'found' without specifying whether to return to storage or inject into workflow..."
			end
		end
		@po_returns = PhysicalObject.where(id: @po_returns.map(&:to_i))
		@po_injects = PhysicalObject.where(id: @po_injects.map(&:to_i))

		PhysicalObject.transaction do
			# handle returns
			@po_returns.each do |p|
				ws = WorkflowStatus.build_workflow_status(p.storage_location, p, true)
				p.workflow_statuses << ws
				p.current_workflow_status = ws
				p.save
			end

			# handle any CG creation
			if @po_injects.size > 0
				@cg = ComponentGroup.new(title_id: params[:title_id].to_i, group_type: params[:cg_type], group_summary: "This component group was created from 'finding' missing Physical Objects")
				@cg.save
				@po_injects.each do |p|
					settings = params[:component_group][:component_group_physical_objects][p.id.to_s]
					cgpo = ComponentGroupPhysicalObject.new(
							physical_object_id: p.id, component_group_id: @cg.id, scan_resolution: settings[:scan_resolution],
							clean: settings[:clean], return_on_reel: settings[:return_on_reel], color_space: settings[:color_space]
					)
					cgpo.save
					p.active_component_group = @cg
					ws = WorkflowStatus.build_workflow_status(settings[:location], p, true)
					p.workflow_statuses << ws
					p.current_workflow_status = ws
					p.save!
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

	end
