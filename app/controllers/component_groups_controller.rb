class ComponentGroupsController < ApplicationController
  include AlfHelper

  before_action :set_component_group, only:
		[:destroy, :ajax_physical_objects_list, :remove_physical_object, :add_physical_objects, :ajax_queue_pull_request, :ajax_move_into_active_request, :ajax_edit_summary]

  # GET /component_groups
  # GET /component_groups.json
  def index
    @component_groups = ComponentGroup.all
  end

  # GET /component_groups/1
  # GET /component_groups/1.json
  def show
    @title = Title.find(params[:title_id])
    @component_group = ComponentGroup.find(params[:id])
  end

  def new
    @title = Title.find(params[:id])
    @component_group = ComponentGroup.new(title_id: @title.id)
    @component_group_cv = ControlledVocabulary.component_group_cv
  end

  # POST /component_groups
  # POST /component_groups.json
  def create
    @title = Title.find(params[:component_group][:title_id])
    begin
      ComponentGroup.transaction do
        @component_group = ComponentGroup.new(component_group_params)
        @checked = params[:component_group][:component_group_physical_objects].keys.select{|k| !params[:component_group][:component_group_physical_objects][k][:selected].nil?}
        @component_group.save!
        @checked.each do |po|
          settings = params[:component_group][:component_group_physical_objects][po]
          ComponentGroupPhysicalObject.new(
              component_group_id: @component_group.id, physical_object_id: po.to_i,
              scan_resolution: settings[:scan_resolution], color_space: settings[:color_space], return_on_reel: settings[:return_on_reel], clean: settings[:clean]
          ).save!
        end
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end

    if @component_group.persisted?
      flash[:notice] = "Component Group successfully created"
    else
      flash[:warning] = "Component Group was not created..."
    end
    redirect_to title_path(@title)
  end

  # GET /component_groups/1/edit
  def edit
    @title = Title.find(params[:t_id])
    @component_group = ComponentGroup.includes(:physical_objects).find(params[:id])
    @active = @component_group.in_active_workflow?
    @component_group_cv = ControlledVocabulary.component_group_cv
  end

  # PATCH/PUT /component_groups/1
  # PATCH/PUT /component_groups/1.json
  def update
    @component_group = ComponentGroup.find(params[:id])
    begin
      ComponentGroup.transaction do
        @active = @component_group.in_active_workflow?
        @original = @component_group.physical_objects
        ComponentGroupPhysicalObject.where(component_group_id: @component_group.id).delete_all
        @checked = params[:component_group][:component_group_physical_objects].keys.select{|k| !params[:component_group][:component_group_physical_objects][k][:selected].nil?}
        @component_group.group_type = params[:component_group][:group_type]
        @component_group.group_summary = params[:component_group][:group_summary]
        @component_group.save!
        flash[:notice] = "Component Group successfully created.".html_safe
        @checked.each do |po|
          settings = params[:component_group][:component_group_physical_objects][po]
          ComponentGroupPhysicalObject.new(
              component_group_id: @component_group.id, physical_object_id: po.to_i,
              scan_resolution: settings[:scan_resolution], color_space: settings[:color_space], return_on_reel: settings[:return_on_reel], clean: settings[:clean]
          ).save!
          p = PhysicalObject.find(po)
          # must do this before setting workflow status so that the correct CG can be assigned to the workflow status
          p.active_component_group = @component_group
          if @active && p.in_storage?
            p.workflow_statuses << WorkflowStatus.build_workflow_status(WorkflowStatus::QUEUED_FOR_PULL_REQUEST, p)
            flash[:notice] = "#{flash[:notice]}<br/>#{p.iu_barcode} has been Queued for Pull Request"
          elsif @active && (p.current_location == WorkflowStatus::JUST_INVENTORIED_ALF)
            p.workflow_statuses << WorkflowStatus.build_workflow_status(WorkflowStatus::TWO_K_FOUR_K_SHELVES, p)
            flash[:notice] = "#{flash[:notice]}<br/>#{p.iu_barcode} should be moved to the 2k/4k staging shelf"
          elsif @active && (p.current_location == WorkflowStatus::JUST_INVENTORIED_WELLS)
            loc = @component_group.group_type == ComponentGroup::BEST_COPY_MDPI_WELLS ? WorkflowStatus::BEST_COPY_MDPI_WELLS : WorkflowStatus::WELLS_TO_ALF_CONTAINER
            p.workflow_statuses << WorkflowStatus.build_workflow_status(loc, p)
            flash[:notice] = "#{flash[:notice]}<br/>#{p.iu_barcode} should be moved to '#{loc}'"
          end
          p.save
        end
      end
    rescue Exception => e
      flash[:warning] = "An error occurred while editing the Component Group, no changes were made: #{e.message}"
    end
    redirect_to title_path(@component_group.title)
  end

  # DELETE /component_groups/1
  # DELETE /component_groups/1.json
  def destroy
    authorize ComponentGroup
    @component_group.destroy
    respond_to do |format|
      format.html { redirect_to :back, notice: 'Component group was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def best_copy_selection
    @title = Title.find(params[:title_id])
    @component_group = ComponentGroup.find(params[:component_group_id])
  end

  def best_copy_selection_create
    @component_group = ComponentGroup.find(params[:component_group_id])
    @title = Title.find(params[:title_id])
    keys = params[:component_group][:component_group_physical_objects_attributes].keys
    checked = keys.select{|k| !params[:component_group][:component_group_physical_objects_attributes][k][:selected].nil?}
    unchecked = keys.select{|k| params[:component_group][:component_group_physical_objects_attributes][k][:selected].nil? }
    ComponentGroup.transaction do
      if checked.size > 0
        @new_cg = ComponentGroup.new(group_type: ComponentGroup::REFORMATTING_MDPI, group_summary: params[:component_group][:group_summary])
        @new_cg.title = @title
        @new_cg.save
        checked.each do |pid|
          settings = params[:component_group][:component_group_physical_objects_attributes][pid]
          p = PhysicalObject.find(pid)
          p.active_component_group = @new_cg
          cgpo = ComponentGroupPhysicalObject.new(component_group_id: @new_cg.id, physical_object_id: pid,
                    scan_resolution: settings[:scan_resolution], color_space: settings[:color_space],
                    return_on_reel: settings[:return_on_reel], clean: settings[:clean])
          p.component_group_physical_objects << cgpo
          location = nil
          if @component_group.group_type == ComponentGroup::BEST_COPY_ALF
            location = WorkflowStatus::TWO_K_FOUR_K_SHELVES
          elsif @component_group.group_type == ComponentGroup::BEST_COPY_MDPI_WELLS
            location = WorkflowStatus::WELLS_TO_ALF_CONTAINER
          else
            raise "Cannot create reformatting component group from #{@component_group.group_type}"
          end
          ws = WorkflowStatus.build_workflow_status(location, p)
          p.workflow_statuses << ws
          p.save
        end
      end
      unchecked.each do |pid|
        p = PhysicalObject.find(pid)
        ws = WorkflowStatus.build_workflow_status(p.storage_location, p)
        p.workflow_statuses << ws
        p.active_component_group = nil
        p.save
      end
    end
    flash[:notice] = "A new Reformatting Component Group was successfully created."
    redirect_to @title
  end

  def move_to_mdpi_workflow
    @title = Title.find(params[:t_id])
    @component_group = ComponentGroup.find(params[:id])
    if @component_group.is_iulmia_workflow?
      @new_cg = ComponentGroup.new
      @component_group_cv = ControlledVocabulary.component_group_cv[:group_type].select{ |t| t[0].include?('MDPI')}
    end
  end

  def move_to_mdpi_workflow_create
    PhysicalObject.transaction do
      keys = params[:component_group][:component_group_physical_objects_attributes].keys
      checked = keys.select{|k| !params[:component_group][:component_group_physical_objects_attributes][k][:selected].nil?}
      @pos = PhysicalObject.where(id: checked)
      @return = ComponentGroup.find(params[:id]).physical_objects - @pos
      @cg = ComponentGroup.new(title_id: params[:t_id], group_type: params[:component_group][:group_type], group_summary: params[:component_group][:group_summary])
      @pos.each do |p|
        settings = params[:component_group][:component_group_physical_objects_attributes][p.id.to_s]
        @cg.physical_objects << p
        @cg.save
        p.active_component_group = @cg
        loc = p.in_active_workflow? ? get_next_loc(p) : WorkflowStatus::QUEUED_FOR_PULL_REQUEST
        ws = WorkflowStatus.build_workflow_status(loc, p)
        p.workflow_statuses << ws
        p.current_workflow_status = ws
        p.save
        p.active_scan_settings.update_attributes(scan_resolution: settings[:scan_resolution], color_space: settings[:color_space], return_on_reel: settings[:return_on_reel], clean: settings[:clean])
      end
      @return.each do |p|
        p.active_component_group = nil
        ws = WorkflowStatus.build_workflow_status(p.storage_location, p)
        p.workflow_statuses << ws
        p.current_workflow_status = ws
        p.save
      end
    end
    flash[:inject] = true
    @title = Title.find(params[:t_id])
    @physical_objects = @title.physical_objects
    @component_group_cv = ControlledVocabulary.component_group_cv
    render 'titles/show'
  end

  def ajax_queue_pull_request
    # result = pull_request([@component_group.id])
    # render text: result, status: (result == "failure" ? 500 : 200)
    @component_group = ComponentGroup.find(params[:id])
    bad = {}
    begin
      PhysicalObject.transaction do
        @component_group.physical_objects.each do |p|
          status = p.current_workflow_status
          if !status.can_be_pulled?
            bad[p.id] = "#{p.iu_barcode} is not <i>In Storage</i> it is: <b>#{status.status_name}</b>".html_safe
          else
            # must set active component group BEFORE building the next workflow status, WorkflowStatus needs to set the component group id on it
            p.active_component_group = @component_group
            ws = WorkflowStatus.build_workflow_status(WorkflowStatus::QUEUED_FOR_PULL_REQUEST, p)
            p.workflow_statuses << ws
	          p.save!
          end
        end
        if bad.size > 0
          raise ManualRollBackError.new
        else
          render text: 'success'
        end
      end
    rescue ManualRollBackError => e
      render json: bad.to_json
    end
  end

  def ajax_move_into_active_request
    bad = {}
    begin
      PhysicalObject.transaction do
        @component_group.physical_objects.each do |p|
          status = p.current_workflow_status
          if !status.just_inventoried?
            bad[p.id] = "#{p.iu_barcode} is not at <i>Just Inventoried (Wells or ALF)</i> it is: <b>#{status.status_name}</b>".html_safe
          else
            # must set active component group BEFORE building the next workflow status, WorkflowStatus needs to set the component group id on it
            p.active_component_group = @component_group
            stat = nil
            gt = p.active_component_group.group_type
            if p.active_component_group.is_mdpi_workflow?
              if gt == ComponentGroup::REFORMATTING_MDPI
                stat = (p.current_location == WorkflowStatus::JUST_INVENTORIED_ALF ? WorkflowStatus::TWO_K_FOUR_K_SHELVES : WorkflowStatus::WELLS_TO_ALF_CONTAINER)
              else
                stat =  (gt == ComponentGroup::BEST_COPY_ALF ? WorkflowStatus::BEST_COPY_ALF : WorkflowStatus::BEST_COPY_MDPI_WELLS)
              end
            else
              stat = WorkflowStatus::IN_WORKFLOW_WELLS
            end
            ws = WorkflowStatus.build_workflow_status(stat, p)
            p.workflow_statuses << ws
            p.save!
          end
        end
        if bad.keys.size > 0
          raise ManualRollBackError.new
        else
          render text: 'success'
        end
      end
    rescue ManualRollBackError => e
      render json: bad.to_json
    end
  end

  def ajax_physical_objects_list
    render partial: 'ajax_physical_objects_list'
  end

  def ajax_edit_summary
		update = params[:cg_summary_edit][:summary]
		@component_group.update_attributes(group_summary: update)
		render text: "success"
  end

  # place holder for ajax form to submit change to a component groups summary text
  def cg_summary_edit
    ''
  end

  def add_physical_objects
    params[:cg_pos][:po_ids].split(',').collect { |p| p.to_i }.each do |po_id|
      ComponentGroupPhysicalObject.transaction do
        if !@component_group.physical_objects.exists?(po_id)
          ComponentGroupPhysicalObject.new(physical_object_id: po_id, component_group_id: @component_group.id).save!
        end
      end
    end

    respond_to do |format|
      format.html { redirect_to title_path(@component_group.title.id), notice: "Physical Objects successfully added to Component Group"}
    end
  end

  def remove_physical_object
    if @component_group.physical_objects.exists?(params[:pid])
      ComponentGroupPhysicalObject.where(physical_object_id: params[:pid], component_group_id: @component_group.id).delete_all
      @msg = "Physical Object removed from Component Group"
    else
      @msg = "The specified Physical Object does not belong to this Component Group"
    end
    respond_to do |format|
      format.html { redirect_to title_path(@component_group.title.id), notice: @msg }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_component_group
      @component_group = ComponentGroup.find(params[:id])
    end

    def true?(s)
      s.to_s.downcase == "true"
    end

    def get_next_loc(physical_object)
      if physical_object.active_component_group.group_type == ComponentGroup::BEST_COPY_MDPI_WELLS
        WorkflowStatus::BEST_COPY_MDPI_WELLS
      else
        WorkflowStatus::WELLS_TO_ALF_CONTAINER
      end
    end


    # Never trust parameters from the scary internet, only allow the white list through.
    def component_group_params
      params.require(:component_group).permit(
        :group_type, :group_summary, :title_id,
        title_attributes: [:id],
        component_group_physical_objects_attributes: [:id, :physical_object_id, :component_group_id, :scan_resolution, :clean, :return_on_reel, :color_space, :_destroy]
      )
    end
end
