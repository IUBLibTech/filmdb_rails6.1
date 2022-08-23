class TitlesController < ApplicationController
  require 'manual_roll_back_error'
  require "axlsx"
  include PhysicalObjectsHelper
  include TitlesHelper
  before_action :set_title, only: [:show, :edit, :update, :destroy, :create_physical_object, :new_physical_object, :ajax_summary, :create_component_group]
  before_action :set_series, only: [:create, :create_ajax, :update]
  before_action :set_physical_object_cv, only:[:create_physical_object, :new_physical_object]
  before_action :set_all_title_cv, only: [:new, :edit, :new_ajax]

  def search
	  if params[:title_text]
		  # find out whether or not to do pagination
		  @count = Title.title_search_count(params[:title_text], params[:series_name_text], params[:date], params[:publisher_text], params[:creator_text], params[:summary_text], params[:location_text], params[:subject_text],
		                               (params[:collection_id] == '0' ? nil : params[:collection_id]), params[:digitized_status], current_user, 0, Title.all.size)
		  if @count > Title.per_page
			  @paginate = true
			  @page = (params[:page] ? params[:page].to_i : 1)
			  @titles = Title.title_search(params[:title_text], params[:series_name_text], params[:date], params[:publisher_text], params[:creator_text], params[:summary_text], params[:location_text], params[:subject_text],
			                               (params[:collection_id] == '0' ? nil : params[:collection_id]), params[:digitized_status], current_user, (@page - 1) * Title.per_page, Title.per_page)
		  else
			  @titles = Title.title_search(params[:title_text], params[:series_name_text], params[:date], params[:publisher_text], params[:creator_text], params[:summary_text], params[:location_text], params[:subject_text],
			                               (params[:collection_id] == '0' ? nil : params[:collection_id]), params[:digitized_status], current_user, 0, @count)
		  end
    end
    respond_to do |format|
      format.html {render :index}
    end
  end

  # def csv_search
  #   # if params[:title_text]
  #   #   # find out whether or not to do pagination
  #   #   @count = Title.title_search_count(params[:title_text], params[:series_name_text], params[:date], params[:publisher_text], params[:creator_text], params[:summary_text], params[:location_text], params[:subject_text], (params[:collection_id] == '0' ? nil : params[:collection_id]), current_user, 0, Title.all.size)
  #   #   @titles = Title.title_search(params[:title_text], params[:series_name_text], params[:date], params[:publisher_text], params[:creator_text], params[:summary_text], params[:location_text], params[:subject_text], (params[:collection_id] == '0' ? nil : params[:collection_id]), current_user, 0, @count)
  #   # end
  #   # respond_to do |format|
  #   #   format.csv {send_data title_search_to_csv(@titles), filename: 'title_search.csv' }
  #   # end
  #
  # end

  def xls_search
    # this is a stale request - the user hit the back/forward button to arrive here do NOT recreate the SpreadSheetSearch
    if SpreadSheetSearch.where(request_ts: params[:ts]).any?
      redirect_to spread_sheet_searches_path
    else
      ss = SpreadSheetSearch.new(
        user_id: User.current_user_object.id, title_text: params[:title_text], series_name: params[:series_name_text],
        date_text: params[:date_text], publisher_text: params[:publisher_text], creator_text: params[:creator_text],
        summary_text: params[:summary_text], location_text: params[:location_text], subject_text: params[:subject_text],
        collection_id: params[:collection_id], digitized_status: params[:digitized_status], percent_complete: 0, request_ts: params[:request_ts]
      )
      ss.save!
      ss.delay.create
      flash[:notice] = "Your search is running and will be available here for download when it completes."
      redirect_to spread_sheet_searches_path
    end
  end

  # GET /titles/1
  # GET /titles/1.json
  def show
    @physical_objects = @title.physical_objects
    @component_group_cv = ControlledVocabulary.component_group_cv
    if @physical_objects.any?{|p| p.digitized?}

    end
  end

  # GET /titles/new_physical_object
  def new
    u = User.current_user_object
    @title = Title.new(modified_by_id: u.id, created_by_id: u.id)
  end

  # GET /titles/1/edit
  def edit
    @title.modified_by_id = User.current_user_object.id
    if @title.nil?
      flash.now[:warning] = "No such title..."
      redirect_to :back
    end
  end

  # POST /titles
  # POST /titles.json
  def create
    @title = Title.new(title_params)
    if @series
      @title.series_id = @series.id
    elsif !params[:title][:series_title_text].blank?
      @series = Series.new(title: params[:title][:series_title_text])
      @series.save
      @title.series_id = @series.id
    end
    respond_to do |format|
      if @title.save
        format.html { redirect_to @title, notice: 'Title was successfully created.' }
        format.json { render :show, status: :created, location: @title }
      else
        format.html { render :new_physical_object }
        format.json { render json: @title.errors, status: :unprocessable_entity }
      end
    end
  end

  def split_title
    @title = Title.find(params[:id])
  end

  def split_title_update

  end

  def show_split_title
	  @title = Title.find(params[:id])
  end


  def create_component_group
    @component_group_cv = ControlledVocabulary.component_group_cv
    po_ids = params[:pos][:po_ids].split(",")
    # make sure that all submitted po ids actually belong to the title
    pos = PhysicalObject.where(id: po_ids)
    bad = pos.reject { |p| p.belongs_to_title? @title.id }.collect { |p| p.iu_barcode }
    respond_to do |format|
      if bad.size > 0
        format.html { render :show, warning: "The following Physical Objects do not belong to this title: #{bad.map(&:inspect).join(", ")}"}
      else
        cg = nil
        ComponentGroup.transaction do
          cg = ComponentGroup.new(
            group_type: params[:pos][:group_type], title_id: @title.id,
            group_summary: params[:pos][:group_summary],
            scan_resolution: (params['HD'] ? 'HD' : (params['5k'] ? '5k' : (params['4k'] ? '4k' : params['2k'] ? '2k' : nil))),
            return_on_reel: (params[:pos][:return_on_reel] == 'Yes' ? true : false),
            clean: params[:pos][:clean],
            color_space: params[:pos][:color_space]
          )
          cg.save!
          pos.each do |p|
            ComponentGroupPhysicalObject.new(physical_object_id: p.id, component_group_id: cg.id).save!
          end
        end
        format.html { redirect_to title_path(@title), notice: "Component Group <i>#{cg.group_type}</i> Created." }
      end
    end
  end

  def new_ajax
    u = User.current_user_object
    @title = Title.new(modified_by_id: u.id, created_by_id: u.id);
    @series = Series.where(id: params[:series_id]).first
    @title.series = @series
    render partial: 'form'
  end

  def create_ajax
    @title = Title.new(title_params)
    if @series
      @title.series_id = @series.id
    elsif !params[:title][:series_title_text].blank?
      @series = Series.new(title: params[:title][:series_title_text])
      @series.save
      @title.series_id = @series.id
    end
    respond_to do |format|
      if @title.save
        format.json {render json: {title_id: @title.id, title_text: @title.title_text, series_id: (@series.nil? ? 0 : @series.id), series_title: @series.nil? ? '' : @series.title}, status: :created}
      else
        format.json {
          render json: { error: 'Something bad happened while trying to save the title...', status: :unprocessable_entity }
        }
      end
    end
  end

  # PATCH/PUT /titles/1
  # PATCH/PUT /titles/1.json
  def update
    respond_to do |format|
	    @tp = title_params
	    if !@series && !params[:title][:series_title_text].blank?
		    @series = Series.new(title: params[:title][:series_title_text])
		    @series.save
		    @tp[:series_id] = @series.id
      end
      last_mod_id = @title&.modifier.nil? ? nil : @title.modifier.id
      if @title.update(@tp)
        Modification.new(object_type: 'Title', object_id: @title.id, user_id: last_mod_id).save
        @title.modifier = User.current_user_object
        @title.save
        format.html { redirect_to @title, notice: 'Title was successfully updated.' }
        format.json { render :show, status: :ok, location: @title }
      else
        format.html { render :edit }
        format.json { render json: @title.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /titles/1
  # DELETE /titles/1.json
  def destroy
    authorize Title
    if @title.physical_objects.size == 0
      @title.destroy
      respond_to do |format|
        format.html { redirect_to titles_url, notice: 'Title was successfully destroyed.' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        flash[:warning] = "Cannot delete a Title that has Physical Objects"
        format.html {redirect_to @title}
      end
    end
  end

  # title merge from search page
  def titles_merge
	  @titles = Title.where(id: params[:title_ids].split(',').collect { |t| t.to_i })
  end

  # post for merging titles from search page
  def merge_titles
	  @master = Title.find(params[:master])
	  @mergees = Title.where(id: params[:selected].split(','))
	  failed = title_merge(@master, @mergees)
	  if failed.size > 0
		  links = failed.collect{ |t| view_context.link_to t.title_text, title_path(t), target: '_blank' }.join(', ')
		  flash[:warning] = "The following Titles are in active workflow and were not merged: #{links}"
	  end
	  if @mergees.size > failed.size
		  flash[:notice] = "#{@mergees.size - failed.size} Title(s) were merged into #{@master.title_text}"
	  end
	  redirect_to @master
  end

  # action that merges only titles that are in storage
  def merge_in_storage
    render 'title_merge_selection'
  end
  # the POST counter
  def merge_in_storage_update

  end

  # returns an array containing the total count of physical objects for this title at index 0,
  # followed by the total count of physical objects in active workflow at index 1
  def ajax_reel_count
	  @title = Title.find(params[:id])
	  c = 0
	  @title.physical_objects.each do |p|
		  cs = p.current_workflow_status
		  c += 1 if (!cs.nil? && !WorkflowStatus.is_storage_status?(cs.status_name)) &&	cs.status_name != WorkflowStatus::JUST_INVENTORIED_ALF && cs.status_name != WorkflowStatus::JUST_INVENTORIED_WELLS
	  end
	  ar = [@title.physical_objects.size, c]
	  render json: ar
	end


  ##### These actions are all related to handling title merge through the "title autocomplete" selection process ######
  # get for title merging from ajax autcomplete title selection
  def title_merge_selection

  end
  # ajax page returns a table row for the specified title
  def title_merge_selection_table_row
    @title = Title.find(params[:id])
    if (params[:merge_all] == 'true' || (params[:merge_all] == 'false' && !@title.in_active_workflow?))
      render partial: 'title_merge_selection_table_row'
    else
      render text: "Active"
    end
  end
  # ajax call that renders a table containing all the physical objects for the specified title ids
  def merge_physical_object_candidates
	  @physical_objects = Title.where(id: params[:ids]).collect{ |t| t.physical_objects }.flatten
	  @component_group_cv = ControlledVocabulary.component_group_cv
	  render partial: 'merge_physical_object_candidates'
  end

  # ajax call for a set of titles associated with physical objects (pre-split) for creating component groups
  def split_title_cg_table
    @title = Title.find(params[:id])
    @map = JSON.parse(params[:title_map]).collect{|v| [v[0], v[1]]}
    @retitled_ids = @map.select{|v| v[0] != @title.id }.collect{|v| v[1]}.flatten
    @map = @map.to_h
    render partial: 'split_title_cg_table'
  end

  # does the actual title merge for ajax search based merging
  def merge_autocomplete_titles
    begin
      PhysicalObject.transaction do
        @component_group_cv = ControlledVocabulary.component_group_cv
        @master = Title.find(params[:master_title_id])
        @title = @master
        @mergees = Title.where("id in (?)", params[:mergees].split(',').collect{ |s| s.to_i})
        @moved = []
        failed = title_merge(@master, @mergees, true)
        if failed.size > 0
          raise ManualRollBackError.new("The following titles could not be merged: #{failed.collect{|t| [t.title_text]}.join(',')}")
        end
        unless params[:component_group].nil?
          flash[:merged] ||= {}
          flash[:merged][:all] = true
          keys = params[:component_group][:component_group_physical_objects_attributes].keys
          # check_box_tag does not work the same way as the helper f.check_box with respect to the params hash.
          # One must manually check the presence of the attribute - HTML forms do no post unchecked checkboxes so if it's present, it was checked
          checked = keys.select{|k| !params[:component_group][:component_group_physical_objects_attributes][k][:checked].nil?}
          @return = keys.select{|k| !params[:component_group][:component_group_physical_objects_attributes][k][:return].nil?}
          if checked.size > 0
            @component_group = ComponentGroup.new(title_id: @master.id, group_type: params[:component_group][:group_type], group_summary: params[:component_group][:group_summary])
            @component_group.save
            checked.each do |poid|
              po = PhysicalObject.find(poid)
              ws = get_split_workflow_status(@component_group, po)
              @moved << po if po.current_location != ws.status_name
              settings = params[:component_group][:component_group_physical_objects_attributes][poid]
              po.workflow_statuses << ws unless ws.nil?
              @component_group.physical_objects << po
              @component_group.save
              po.active_component_group = @component_group
              po.save
              po.active_scan_settings.update_attributes(scan_resolution: settings[:scan_resolution], color_space: settings[:color_space], return_on_reel: settings[:return_on_reel], clean: settings[:clean])
            end
          end
          @return.each do |poid|
            po = PhysicalObject.find(poid)
            if po.current_workflow_status.in_workflow?
              ws = WorkflowStatus.build_workflow_status(po.storage_location, po)
              po.workflow_statuses << ws
              po.save
              @moved << po
            end
          end
        end
      end
      flash[:merge] = true
    rescue ManualRollBackError => e
      puts e.message
      puts e.backtrace.join('\n')
      flash[:merge] = false
      flash[:warning] = "Something bad happened: #{e.message}"
    end
    @title.reload
    render 'titles/show'
  end

  def update_split_title
    @component_group_cv = ControlledVocabulary.component_group_cv
    @title = Title.find(params[:id])
    # converts the JavaScript Map object into a Ruby hash { title_id => [array of physical object ids]}. This map contains
    # title ids mapped to the list of physical object ids. If the map key == @title (the title that is being split),
    # this particular key binding signifies those physical objects that should REMAIN associated with @title. Everything else is a retitle.
    @map = JSON.parse(params[:title_map]).to_h
    # convenience map of title ids pointing to a hash that contains :retitled => all PhysicalObjects that were reassigned,
    # :moved => all PhysicalObjects (including those from the target title) whose location was updated as a result of retitling
    # {title_id => {:retitled => [POs reassigned to title_id], :moved => [POs whose location was changed as a result]}, ...}
    @retitled = {}
    Title.transaction do
      @map.keys.each do |t_id|
        @retitled[t_id] = {:retitled => [], :moved => []}
        if @map[t_id].size > 0
          cur_title = Title.find(t_id)
          pos = PhysicalObject.where(id: @map[t_id])

          # remove association with old title and add new association if it doesn't already exist
          if cur_title != @title
            @retitled[t_id][:retitled] = pos
            pos.each do |p|
              p.component_group_physical_objects.where(physical_object_id: p.id).delete_all
              p.physical_object_titles.where(title_id: @title.id).delete_all
              p.active_component_group = nil
              # it's remotely possible that the PO already belongs to this title (AND  @title)
              PhysicalObjectTitle.new(title_id: cur_title.id, physical_object_id: p.id).save! unless p.titles.include?(cur_title)
            end
          end

          # create component groups if necessary
          # grabs all existing physical object ids belonging to cur_title AND any that are being reassigned from @title
          keys = params[:titles][t_id.to_s][:component_group][:component_group_physical_objects_attributes].keys
          # grabs all physical object ids that were selected for inclusion in the component group
          @checked = keys.select{|k| !params[:titles][t_id.to_s][:component_group][:component_group_physical_objects_attributes][k][:checked].nil?}
          @return = keys.select{|k| !params[:titles][t_id.to_s][:component_group][:component_group_physical_objects_attributes][k][:return].nil?}
          if @checked.size > 0
            @new_cg = ComponentGroup.new(title_id: t_id.to_s, group_type: params[:titles][t_id.to_s][:component_group][:group_type], group_summary: params[:titles][t_id.to_s][:component_group][:group_summary])
            @new_cg.save
            @checked.each do |pid|
              po = pos.find{ |po| po.id == pid.to_i}
              if po.nil?
                po = cur_title.physical_objects.find {|p| p.id == pid.to_i }
              end
              raise "How'd this happen?!?" if po.nil?
              settings = params[:titles][t_id.to_s][:component_group][:component_group_physical_objects_attributes][pid]
              ComponentGroupPhysicalObject.new(
                  component_group_id: @new_cg.id, physical_object_id: po.id,
                  scan_resolution: settings[:scan_resolution], color_space: settings[:color_space], return_on_reel: settings[:return_on_reel], clean: settings[:clean]
              ).save!
              po.active_component_group = @new_cg
              ws = get_split_workflow_status(@new_cg, po)
              raise "Workflow status should not be null..." if ws.nil?
              if ws.status_name != po.current_location
                @retitled[t_id][:moved] << po
              end
              po.workflow_statuses << ws
              po.save
            end
          end
          @return.each do |pid|
            po = PhysicalObject.find(pid)
            @retitled[t_id][:moved] << po unless (po.current_workflow_status.is_storage_status? || po.current_location == WorkflowStatus::SHIPPED_EXTERNALLY)
            po.workflow_statuses << WorkflowStatus.build_workflow_status(po.storage_location, po) unless (po.current_workflow_status.is_storage_status? || po.current_location == WorkflowStatus::SHIPPED_EXTERNALLY)
            po.active_component_group = nil
            po.save
          end
        end
      end
    end
    flash[:split] = true
    render 'show'
  end

  def new_physical_object
    @em = 'Creating New Physical Object'
    @physical_object = PhysicalObject.new
    @physical_object.titles << @title
    render 'physical_objects/new_physical_object'
  end

  def autocomplete_title
    if params[:term]
      if params[:exclude]
        @titles = Title.joins("LEFT JOIN `series` ON `series`.`id` = `titles`.`series_id`").where("title_text like ? AND titles.id not in (?)", "%#{params[:term]}%", params[:exclude]).select('titles.id, title_text, titles.summary, series_id, series.title').order(:title_text)
      else
        @titles = Title.joins("LEFT JOIN `series` ON `series`.`id` = `titles`.`series_id`").where("title_text like ? ", "%#{params[:term]}%").select('titles.id, title_text, titles.summary, series_id, series.title').order(:title_text)
      end
      json = @titles.to_json
      json.gsub! "\"title_text\":", "\"label\":"
      json.gsub! "\"id\":", "\"value\":"
      json.gsub! "\"title\":", "\"series_title\":"
      render json: json
    else
      render json: ''
    end
  end


  def autocomplete_title_for_series
    if params[:series_id] && params[:term]
      json = Title.where("series_id = ? and title_text like ?", params[:series_id], "%#{params[:term]}%").select(:id, :title_text, :summary).to_json
      json.gsub! "\"title_text\":", "\"label\":"
      json.gsub! "\"id\":", "\"value\":"
      render json: json
    else
      render json: ''
    end
  end

  def ajax_summary
    render partial: 'ajax_show'
  end

  def autocomplete_title_for_collection

  end

  def ajax_edit_cg_params
    @cg = ComponentGroup.find(params[:id])
	  render partial: 'ajax_edit_cg_params'
  end

  def get_split_workflow_status(component_group, po)
    cl = po.current_location
    ws = nil
    if component_group.group_type == ComponentGroup::REFORMATTING_MDPI && (cl == WorkflowStatus::BEST_COPY_MDPI_WELLS || cl == WorkflowStatus::BEST_COPY_ALF)
      ws = WorkflowStatus.build_workflow_status(
          cl == WorkflowStatus::BEST_COPY_ALF ? WorkflowStatus::TWO_K_FOUR_K_SHELVES : WorkflowStatus::WELLS_TO_ALF_CONTAINER, po
      ) unless cl == WorkflowStatus::QUEUED_FOR_PULL_REQUEST
    elsif component_group.group_type == ComponentGroup::REFORMATTING_MDPI
      raise ManualRollBackError.new("The merge failed: #{po.iu_barcode}'s current location is #{cl}. It cannot be added to a Reformatting (MDPI) component group.")
    elsif (component_group.group_type == ComponentGroup::BEST_COPY_ALF || component_group.group_type == ComponentGroup::BEST_COPY_MDPI_WELLS) && (po.current_workflow_status.in_workflow? || po.current_workflow_status.is_storage_status?)
      # need to force these workflow location changes because some items might be at best already, and going from
      # there to there isn't normally allowed - it only happens during title merge/split
      loc = next_bc_loc(component_group, po)
      if component_group.group_type == ComponentGroup::BEST_COPY_ALF
        ws = WorkflowStatus.build_workflow_status(loc, po, true)
      else
        ws = WorkflowStatus.build_workflow_status(loc, po, true)
      end
    else
      flash.now[:warning] = "Cannot add #{po.iu_barcode} to a #{@component_group.group_type} Component Group. It is currently #{po.current_location}"
      raise "Cannot add to component group..."
    end
    ws
  end

  def next_bc_loc(component_group, po)
    if po.current_workflow_status.is_storage_status?
      WorkflowStatus::QUEUED_FOR_PULL_REQUEST
    elsif po.current_location == WorkflowStatus::QUEUED_FOR_PULL_REQUEST || po.current_location == WorkflowStatus::PULL_REQUESTED
      po.current_location
    elsif po.current_workflow_status.in_workflow?
      if component_group.group_type == ComponentGroup::BEST_COPY_ALF
        WorkflowStatus::BEST_COPY_ALF
      elsif component_group.group_type == ComponentGroup::BEST_COPY_MDPI_WELLS
        WorkflowStatus::BEST_COPY_MDPI_WELLS
      else
        raise "Cannot add #{po.iu_barcode} to component group. It's current location is: #{po.current_location}"
      end
    else
      raise "Cannot add #{po.iu_barcode} to component group. It's current location is: #{po.current_location}"
    end
  end

  def get_merge_workflow_status(component_group, po)
    cl = po.current_location
    ws = nil
    if component_group.group_type == ComponentGroup::REFORMATTING_MDPI && (cl == WorkflowStatus::BEST_COPY_MDPI_WELLS || cl == WorkflowStatus::BEST_COPY_ALF)
      ws = WorkflowStatus.build_workflow_status(cl == WorkflowStatus::BEST_COPY_ALF ? WorkflowStatus::TWO_K_FOUR_K_SHELVES : WorkflowStatus::WELLS_TO_ALF_CONTAINER, po) unless cl == WorkflowStatus::QUEUED_FOR_PULL_REQUEST
    elsif component_group.group_type == ComponentGroup::REFORMATTING_MDPI
      raise ManualRollBackError.new("The merge failed: #{po.iu_barcode}'s current location is #{cl}. It cannot be added to a Reformatting (MDPI) component group.")
    elsif (component_group.group_type == ComponentGroup::BEST_COPY_ALF || component_group.group_type == ComponentGroup::BEST_COPY_MDPI_WELLS) && (po.current_workflow_status.in_workflow? || po.current_workflow_status.is_storage_status?)
      # need to force these workflow location changes because some items might be at best already, and going from
      # there to there isn't normally allowed - it only happens during title merge/split
      que = po.current_workflow_status.is_storage_status?
      if component_group.group_type == ComponentGroup::BEST_COPY_ALF
        ws = WorkflowStatus.build_workflow_status(que ? WorkflowStatus::QUEUED_FOR_PULL_REQUEST : WorkflowStatus::BEST_COPY_ALF, po, true)
      else
        ws = WorkflowStatus.build_workflow_status(que ? WorkflowStatus::QUEUED_FOR_PULL_REQUEST : WorkflowStatus::BEST_COPY_MDPI_WELLS, po, true)
      end
    else
      flash.now[:warning] = "Cannot add #{po.iu_barcode} to a #{@component_group.group_type} Component Group. It is currently #{po.current_location}"
      raise "Cannot add to component group..."
    end
    ws
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_title
    @title = Title.find(params[:id])
    @series = @title.series
  end

  def set_series
    @series = Series.find(params[:title][:series_id]) unless params[:title][:series_id].blank?
  end

  def set_all_title_cv
    set_form_cv
    set_genre_cv
    set_title_cv
  end
  def set_physical_object_cv
    @cv = ControlledVocabulary.physical_object_cv('Film')
    @l_cv = ControlledVocabulary.language_cv
    @pod_cv = ControlledVocabulary.physical_object_date_cv
  end
  def set_title_cv
    @title_cv = ControlledVocabulary.title_cv
	  @title_date_cv = ControlledVocabulary.title_date_cv
  end
  def set_form_cv
    @form_cv = ControlledVocabulary.title_form_cv
  end
  def set_genre_cv
    @genre_cv = ControlledVocabulary.title_genre_cv
  end
  def set_creator_cv

  end
  # Never trust parameters from the scary internet, only allow the white list through.
  def title_params
    params.require(:title).permit(
        :title_text, :summary, :series_id, :series_title_index, :modified_by_id, :created_by_id, :series_part, :notes,
        :subject, :name_authority, :country_of_origin, :fully_cataloged, :in_copyright, :copyright_end_date_edtf, :copyright_end_date,
        :copyright_verified_by_iu_cp_research, :copyright_verified_by_viewing_po, :copyright_verified_by_other,
        :copyright_notes, :stream_url,
        title_creators_attributes: [:id, :name, :role, :_destroy],
        title_dates_attributes: [:id, :date_text, :date_type, :_destroy],
        title_genres_attributes: [:id, :genre, :_destroy],
        title_original_identifiers_attributes: [:id, :identifier, :identifier_type, :_destroy],
        title_publishers_attributes: [:id, :name, :publisher_type, :_destroy],
        title_forms_attributes: [:id, :form, :_destroy],
        title_locations_attributes: [:id, :location, :_destroy]
    )
  end
  def page_link_path(page)
	  titles_search_path(page: page, title_text: params[:title_text], series_name_text: params[:series_name_text], date: params[:date], publisher_text: params[:publisher_text], creator_text: params[:creator_text],
	                     collection_id: (params[:collection_id] == '0' ? 0 : params[:collection_id]), digitized_status: params[:digitized_status])
  end
	helper_method :page_link_path

  private
  def prepare_file(file_name)
    Tempfile.new([file_name, '.xlsx'], encoding: 'ascii-8bit')
  end
end
