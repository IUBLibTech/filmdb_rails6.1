class CagesController < ApplicationController
	include CagesHelper
	include ServicesHelper
	include PhysicalObjectsHelper
	require 'manual_roll_back_error'

	before_action :set_cages, only: [:index, :mark_shipped]
  before_action :set_cage, only: [:show, :edit, :update, :destroy, :show_xml, :mark_ready_to_ship, :unmark_ready_to_ship, :mark_shipped]

	before_action :set_cage_shelf, only: [:shelf_physical_objects, :add_physical_object_to_shelf, :remove_physical_object]

	skip_before_filter :verify_authenticity_token, only: [:mark_shipped]
	protect_from_forgery with: :null_session, only: [:mark_shipped]

	def index
		@cages = Cage.includes(:top_shelf, :middle_shelf, :bottom_shelf, [top_shelf: :physical_objects, middle_shelf: :physical_objects, bottom_shelf: :physical_objects]).order('cages.id DESC').load
	end

	# GET /cages/1
  # GET /cages/1.json
  def show
		respond_to do |format|
			format.html
		end
  end

  # GET /cages/new
  def new
	  max = Cage.maximum('id')
    @cage = Cage.new(identifier: "Cage #{max.nil? ? 1 : max + 1}")
	  @cage.top_shelf.identifier = "Top Shelf"
	  @cage.middle_shelf.identifier ="Middle Shelf"
	  @cage.bottom_shelf.identifier = "Bottom Shelf"
  end

  # POST /cages
  # POST /cages.json
  def create
    @cage = Cage.new(cage_params)
    respond_to do |format|
      if @cage.save
				# FIXME: not able to figure out how to set the bi-directional associations in Cage.initialize
				@cage.top_shelf.update_attributes(cage_id: @cage.id)
				@cage.middle_shelf.update_attributes(cage_id: @cage.id)
				@cage.bottom_shelf.update_attributes(cage_id: @cage.id)
        format.html { redirect_to @cage, notice: 'Cage was successfully created.' }
        format.json { render :show, status: :created, location: @cage }
      else
        format.html { render :new }
        format.json { render json: @cage.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cages/1
  # PATCH/PUT /cages/1.json
  def update
    respond_to do |format|
      if @cage.update(cage_params)
        format.html { redirect_to @cage, notice: 'Cage was successfully updated.' }
        format.json { render :show, status: :ok, location: @cage }
      else
        format.html { render :edit }
        format.json { render json: @cage.errors, status: :unprocessable_entity }
      end
    end
	end

	def mark_ready_to_ship
		if @cage.can_be_shipped?
			@cage.update_attributes(ready_to_ship: true)
			flash[:notice] = "Cage #{@cage.identifier} is ready to ship to Memnon"
			redirect_to :cages
		else
			flash.now[:warning] = "Cage #{@cage.identifier} cannot be marked ready to ship. It either contains 0 physical objects, or 1 or more shelves with physical objects does not have an MDPI barcode assigned."
			render :show
		end
	end

	def unmark_ready_to_ship
		if @cage.ready_to_ship
			@cage.update_attributes(ready_to_ship: false)
			flash[:notice] = "#{@cage.identifier} was changed to 'Not Ready to Ship'"
		else
			flash[:warning] = "#{@cage.identifier} was not marked 'Ready to Ship' - not change made to database."
		end
		redirect_to :cages
	end

	def mark_shipped
		if @cage.ready_to_ship
			begin
				PhysicalObject.transaction do
					@cage.update_attributes!(shipped: true)
					batch_count = CageShelf.where('shipped is not null').size
					shipped = DateTime.now
					if @cage.top_shelf.physical_objects.size > 0
						@cage.top_shelf.identifier = "FDB-#{(batch_count+1).to_s.rjust(4, "0")}-FILM"
						@cage.top_shelf.shipped = shipped
						@cage.top_shelf.save!
						batch_count+= 1
					end
					flash.now[:notice] = "#{@cage.identifier} was shipped to Memnon"

					if @cage.middle_shelf.physical_objects.size > 0
						@cage.middle_shelf.identifier = "FDB-#{(batch_count+1).to_s.rjust(4, "0")}-FILM"
						@cage.middle_shelf.shipped = shipped
						@cage.middle_shelf.save!
						batch_count+= 1
					end

					if @cage.bottom_shelf.physical_objects.size > 0
						@cage.bottom_shelf.identifier = "FDB-#{(batch_count+1).to_s.rjust(4, "0")}-FILM"
						@cage.bottom_shelf.shipped = shipped
						@cage.bottom_shelf.save!
					end

					@result = push_cage_to_pod(@cage)
					body = @result.body
					unless body == 'SUCCESS'
						@msg = "POD did not receive the push correctly - Responded with message<br/><pre>#{body}</pre>".html_safe
						raise ManualRollBackError, @msg
					end

					# this needs to be done after a SUCCESSFUL push to POD as the new shipped externally status will flag the record
					# as needing to be redigitized
					@cage.top_shelf.physical_objects.each do |p|
						p.workflow_statuses << WorkflowStatus.build_workflow_status(WorkflowStatus::SHIPPED_EXTERNALLY, p)
						p.save!
					end
					@cage.middle_shelf.physical_objects.each do |p|
						p.workflow_statuses << WorkflowStatus.build_workflow_status(WorkflowStatus::SHIPPED_EXTERNALLY, p)
						p.save!
					end
					@cage.bottom_shelf.physical_objects.each do |p|
						p.workflow_statuses << WorkflowStatus.build_workflow_status(WorkflowStatus::SHIPPED_EXTERNALLY, p)
						p.save!
					end
				end
			rescue ManualRollBackError => e
				puts e.message
				puts e.backtrace.join('\n')
				flash[:warning] = "An error occurred while trying to push the cage to POD."
			ensure
				PodPush.new(cage_id: @cage.id, response: @result&.body).save
			end
		else
			flash.now[:warning] = "#{@cage.identifier} could not be shipped to Memnon - it is not ready."
		end
		redirect_to '/cages'
	end

	def shelf_physical_objects
		render partial: 'cage_shelf_physical_objects'
	end

  def add_physical_object_to_shelf
		set_po(params[:cage][:physical_object_iu_barcode])
		if @physical_object.errors.any?
      render partial: 'ajax_add_po_failure'
		else
			begin
				PhysicalObject.transaction do
					@physical_object.mdpi_barcode = params[:cage][:physical_object_mdpi_barcode].to_i if @physical_object.mdpi_barcode.nil?
					@physical_object.cage_shelf_id = @cage_shelf.id
					CageShelfPhysicalObject.new(cage_shelf_id: @cage_shelf.id, physical_object_id: @physical_object.id).save!
					ws = WorkflowStatus.build_workflow_status(WorkflowStatus::IN_CAGE, @physical_object)
					@physical_object.workflow_statuses << ws
					@physical_object.save!
				end
				@msg = "Physical Object #{@physical_object.mdpi_barcode} was successfully added to Shelf #{@physical_object.cage_shelf.identifier}"
				list = @physical_object.waiting_active_component_group_members?
				if list && list.size > 0
					@msg += "<br/>Additional Reels for this title: #{ list.collect{ |p| p.iu_barcode }.join(', ') }".html_safe
				end
				render partial: 'ajax_add_po_success'
			rescue
				@physical_object.errors.add(:save_failed, "Something went wrong when trying to to save Physical Object #{@physical_object.iu_barcode}")
				render partial: 'ajax_add_po_failure'
			end
		end
  end

	def push_result
		@cage = Cage.find(params[:id])
	end

	def remove_physical_object
		# don't add this call to before_action :set_physical_object - the PO is determined by different passed params (mdpi_barcode vs po.id)
		@physical_object = PhysicalObject.find(params[:po_id])
		if @physical_object.cage_shelf != @cage_shelf
			@msg = "Physical Object #{params[:barcode]} is not contained in this Shelf"
			render partial: 'ajax_add_po_failure'
		else
			@msg = "Physical Object #{@physical_object.mdpi_barcode} successfully removed from Shelf #{@cage_shelf.identifier}"
			@physical_object.cage_shelf = nil
			# also delete the join table reference
			CageShelfPhysicalObject.where(cage_shelf_id: @cage_shelf.id, physical_object_id: @physical_object.id).delete_all
			ws = WorkflowStatus.build_workflow_status(WorkflowStatus::TWO_K_FOUR_K_SHELVES, @physical_object)
			@physical_object.workflow_statuses << ws
			@physical_object.save
			@cage_shelf.reload
			render partial: 'ajax_add_po_success'
		end
	end

  # DELETE /cages/1
  # DELETE /cages/1.json
  def destroy
	  authorize Cage
    @cage.destroy
    respond_to do |format|
      format.html { redirect_to cages_url, notice: 'Cage was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

	def show_xml
		file_path = write_xml(@cage)
		render file: file_path, layout: false, status: 200
	end

	def ajax_cage_shelf_stats
		cs = CageShelf.where(id: params[:id]).first
		stats = {}
		if cs.nil?
			stats[:error] = "Could not find cage shelf with ID #{params[:cage_shelf_id]}"
		else
			pos = cs.physical_objects
			stats[:count] = pos.size
			twoK = 0
			fourK = 0
			durationSec = 0
			pos.each do |p|
				p = p.specific
				if !p.current_scan_settings.nil?
					if p.current_scan_settings.scan_resolution == '2k'
						twoK += 1
					end
					if p.current_scan_settings.scan_resolution == '4k'
						fourK += 1
					end
				end
				unless p.footage.blank? || p.gauge.blank?
					durationSec += ((PhysicalObjectsHelper::GAUGES_TO_FRAMES_PER_FOOT[p.gauge] * p.footage) / 24)
				end
			end
			stats[:count_2k] = twoK
			stats[:percent_2k] = (twoK + fourK > 0) ? twoK / (twoK + fourK) : 0
			stats[:count_4k] =  fourK
			stats[:percent_4k] = (twoK + fourK > 0) ? fourK / (twoK + fourK) : 0
			stats[:total_duration] = hh_mm_sec(durationSec)
		end
		render json: stats.to_json
	end

	def ajax_add_physical_object_iu_barcode_scan
		@physical_object = set_po(params[:iu_barcode], false)
		if @physical_object.errors.any?
			render partial: 'ajax_add_po_failure_errors'
		else
			render text: ''
		end
	end

  private
	# Use callbacks to share common setup or constraints between actions.
	def set_cage
		@cage = Cage.find(params[:id])
	end

	def set_cages
		@cages = Cage.all.order('id DESC')
	end

	def set_cage_shelf
		@cage_shelf = CageShelf.find(params[:id])
	end

	def set_physical_object
		@physical_object = PhysicalObject.where(iu_barcode: params[:barcode]).first
	end

	# differs from set_physical_object in that this one may find an actual physical object based on the barcode, but that is not
	# packable
	def set_po(iu_barcode, check_mbc=true)
		@physical_object =  PhysicalObject.where(iu_barcode: iu_barcode).first
		if @physical_object.nil?
			@physical_object = PhysicalObject.new
			@physical_object.errors.add(:iu_barcode, "Could not find record with IU Barcode #{iu_barcode}")
		elsif !@physical_object.cage_shelf.nil? && @physical_object.current_workflow_status.status_name != WorkflowStatus::TWO_K_FOUR_K_SHELVES
			@physical_object.errors.add(:cage_shelf, "#{iu_barcode} has already been added to Cage #{@physical_object.cage_shelf.cage.identifier}")
		else
			# need to check validity of both barcodes
			mbc = params[:cage] ? params[:cage][:physical_object_mdpi_barcode] : nil?
			if check_mbc && mbc.blank?
				@physical_object.errors.add(:mdpi_barcode, "Cannot pack a physical object without an MDPI barcode")
			elsif check_mbc && !ApplicationHelper.valid_barcode?(mbc, true)
				@physical_object.errors.add(:mdpi_barcode, "#{mbc} is not a valid MDPI barcode")
			elsif check_mbc && CageShelf.where(mdpi_barcode: mbc.to_i).size > 0
				@physical_object.errors.add(:mdpi_barcode, "MDPI barcode #{mbc} has already beed assigned to a cage shelf!")
			elsif check_mbc && (!@physical_object.mdpi_barcode.nil? && @physical_object.mdpi_barcode != mbc.to_i)
				@physical_object.errors.add(:mdpi_barcode, "#{@physical_object.iu_barcode} has already been assigned an MDPI barcode: #{@physical_object.mdpi_barcode}")
			elsif !@physical_object.current_workflow_status.valid_next_workflow?(WorkflowStatus::IN_CAGE)
				@physical_object.errors.add(:current_workflow_status, "prevents packing this Physical Object: #{@physical_object.current_workflow_status.type_and_location}")
			else
				if @physical_object.specific.has_attribute?(:gauge) && NONPACKABLE_GAUGES.include?(@physical_object.specific.gauge)
					@physical_object.errors.add(:gauge, "#{@physical_object.gauge} cannot be sent to Memnon. #{@physical_object.iu_barcode} was not added to cage shelf")
				end
			end
		end
		@physical_object
	end

	# Never trust parameters from the scary internet, only allow the white list through.
	def cage_params
		params.require(:cage).permit(:identifier, :notes,
			 #top_shelf: [:id, :identifier, :mdpi_barcode, :notes, :_destroy],
			 #middle_shelf: [:id, :identifier, :mdpi_barcode, :notes, :_destroy],
			 #bottom_shelf: [:id, :identifier, :mdpi_barcode, :notes,:_destroy],
			 top_shelf_attributes: [:id, :identifier, :mdpi_barcode, :notes, :_destroy],
			 middle_shelf_attributes: [:id, :identifier, :mdpi_barcode, :notes, :_destroy],
			 bottom_shelf_attributes: [:id, :identifier, :mdpi_barcode, :notes, :_destroy]
		)
	end
end
