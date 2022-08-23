class PhysicalObjectsController < ApplicationController
  require 'manual_roll_back_error'

  include PhysicalObjectsHelper
  include MailHelper

  before_action :set_physical_object, only: [:show, :show_xml, :edit, :update, :destroy, :mark_missing]
  before_action :acting_as_params, only: [:update_ad_strip]
  # GET /physical_objects
  # GET /physical_objects.json
  def index
    @statuses = WorkflowStatus::ALL_STATUSES.uniq.sort.collect{ |t| [t, t]}
	  if params[:status] && !params[:status].blank?
      @count = PhysicalObject.joins(:current_workflow_status).where("workflow_statuses.status_name = '#{params[:status]}'")
      @count = @count.where("physical_objects.digitized = true") if params[:digitized]
      @count = @count.size
      #@count = PhysicalObject.count_where_current_workflow_status_is(params[:digitized], params[:status])
      if @count > PhysicalObject.per_page
        @paginate = true
        @page = (params[:page].nil? ? 1 : params[:page].to_i)
        #@physical_objects = PhysicalObject.where_current_workflow_status_is((@page - 1) * PhysicalObject.per_page, PhysicalObject.per_page, params[:digitized], params[:status])
        @physical_objects = PhysicalObject.joins(:current_workflow_status).includes([:current_workflow_status, :titles, :active_component_group]).where("workflow_statuses.status_name = '#{params[:status]}'")
        if params[:digitized]
          @physical_objects = @physical_object.where('physical_objects.digitized = true')
        end
        @physical_objects = @physical_objects.offset((@page - 1) * PhysicalObject.per_page).limit(PhysicalObject.per_page)
      else
        #@physical_objects = PhysicalObject.where_current_workflow_status_is(nil, nil, params[:digitized], params[:status])
        @physical_objects = PhysicalObject.joins(:current_workflow_status).includes([:current_workflow_status, :titles, :active_component_group]).where("workflow_statuses.status_name = '#{params[:status]}'")
        @physical_objects = @physical_objects.where('physical_objects.digitized = true') if params[:digitized]
      end
    elsif params[:status] == ''
      @count = (params[:digitized] ? PhysicalObject.where(digitized: true).size : PhysicalObject.all.size)
      @page = (params[:page].nil? ? 1 : params[:page].to_i)
      @paginate = true
		  @physical_objects = (params[:digitized] ?
         PhysicalObject.where(digitized: true).includes([:current_workflow_status, :titles, :active_component_group]).offset((@page - 1) * PhysicalObject.per_page).limit(PhysicalObject.per_page) :
         PhysicalObject.includes([:current_workflow_status, :titles, :active_component_group]).all.offset((@page - 1) * PhysicalObject.per_page).limit(PhysicalObject.per_page)
      )
    else
      @physical_objects = []
	  end
  end

  def compilations
    @comps = PhysicalObject.uniq.order(:compilation).where("compilation is not null AND compilation != ''").pluck(:compilation)
  end
  def compilation_physical_objects
    @physical_objects = PhysicalObject.where(compilation: params[:comp])
  end

  def equipment_technology
    @physical_objects = PhysicalObject.where(medium: 'Equipment/Technology')
    render 'physical_objects/equipment_technology/index'
  end

  # GET /physical_objects/1
  # GET /physical_objects/1.json
  def show
    if session[:physical_object_create_action]
      @continue_url = session[:physical_object_create_action]
      @continue_text = ''
      pattern = /([0-9]+)/
      id = pattern.match(@continue_url) ? pattern.match(@continue_url)[0] : nil
      if @continue_url == new_physical_object_path
        @continue_text = "Continue Creating New Physical Objects"
      elsif @continue_url.include?('collection')
        collection = Collection.find(id)
        @continue_text = "Continue Inventorying Collection <i>#{collection.name}</i>".html_safe
      elsif @continue_url.include?('series')
        series = Series.find(id)
        @continue_text = "Continue Inventorying Series <i>#{series.title}</i>".html_safe
      elsif @continue_url.include?('title')
        title = Title.find(id)
        @continue_text = "Continue Inventorying Title <i>#{title.title_text}</i>".html_safe
      end
    end
    session[:physical_object_create_action] = nil
  end

  def show_xml
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct! :xml, :version=>"1.0"
    @physical_object.specific.to_xml(builder: xml)
    render xml: xml.target!
  end

  # GET /physical_objects/new_physical_object
  def new
    u = User.current_user_object
    if request.get?
      @em = "Creating New Physical Object"
      @physical_object = Film.new(inventoried_by: u.id, modified_by: u.id, media_type: 'Moving Image', medium: 'Film')
      set_cv
    elsif request.post?
      new_one = blank_specific_po(medium_value_from_params)
      new_one.inventoried_by = u.id
      new_one.modified_by = u.id
      new_one.date_inventoried = DateTime.now
      # copy all PhysicalObject only attributes that have been posted
      class_sym = class_symbol_from_params
      params[class_sym].keys.each do |p|
        if PO_ONLY_ATTRIBUTES.include?(p.parameterize.to_sym)
          new_one.send(p+"=", params[class_sym][p])
        end
      end
      # copy any title associations created before the switch, unless it was an Equipment/Technology object in which case it has no titles
      unless params[:equipment_technology]
        params[:physical_object][:title_ids].split(',').each do |t_id|
          new_one.titles << Title.find(t_id.to_i)
        end
      end
      @physical_object = new_one.specific
      set_cv
    else
      raise "How did we get a #{request.method} request here???"
    end
    render 'new_physical_object'
  end
  # POST /physical_objects
  # POST /physical_objects.json
  def create
    create_physical_object
  end

  # GET /physical_objects/1/edit
  def edit
    if request.get?
      if @physical_object.nil?
        flash.now[:warning] = "No such physical object..."
        redirect_to :back
      end
    else
      # so this part is complicated... a POST/PATCH on the #edit action means that the input:select Medium value was
      # changed and we need to rebuild the form based on the Medium value. Because of the shared-by-all-formats attributes
      # and associations that are maintained on the PhysicalObject portion of the original (titles for instance), we need
      # to look at the submit, as some of those values may have been edited. But we need to build a new edit form based
      # on a different Medium than the original object.

      # Now the wonky part: if a user changes from an existing Medium (say Film to Video), then changes BACK to the
      # original Medium, there is no physical workflow where this is correct behavior. It is always user error. In this
      # particular instance, we need to restart the edit process with the original PhysicalObject metadata, ignoring all
      # submits up to this point.
      o_medium = @physical_object.medium
      s_medium = medium_value_from_params

      # only create a new, different Medium, PO if the original and submitted Mediums are different
      if o_medium == s_medium
        flash.now[:warning] = "You have changed this Physical Object back to it's original Medium. Any edits you have made up to this point have been discarded."
      else
        flash.now[:warning] = "You have changed this Physical Object from #{o_medium} to #{s_medium}. Any #{o_medium} metadata will be permanently lost if you update the record."
        # save the original id so that the form can build the route correctly
        @original_po_id = @physical_object.acting_as.id
        new_one = nil
        if s_medium == 'Film'
          new_one = Film.new(po_only_params)
        elsif s_medium == 'Video'
          new_one = Video.new(po_only_params)
        end
        # copy any title associations based on the state of the form when the medium switch occurred
        params[:physical_object][:title_ids].split(',').each do |t_id|
          t = Title.find(t_id.to_i)
          new_one.titles << t unless new_one.titles.include? t
        end
        @physical_object = new_one.specific
      end
    end
    set_cv
    @physical_object.modified_by = User.current_user_object.id
  end

  # PATCH/PUT /physical_objects/1
  # PATCH/PUT /physical_objects/1.json
  def update
    # if the medium has been changed we need to delete the old, medium specific, object
    o_medium = @physical_object.medium
    s_medium = medium_value_from_params
    # active_record-acts_as stomps on creation dates for some reason...
    c = @physical_object.created_at
    begin
      PhysicalObject.transaction do
        # need to cleanup the old specific class that was changed to something else
        Modification.new(object_type: 'PhysicalObject', object_id: @physical_object.acting_as.id, user: @physical_object.modifier).save!
        if o_medium == s_medium
          @physical_object.modifier = User.current_user_object
          #@success = @physical_object.update_attributes!(physical_object_params)
          @physical_object.acting_as.date_inventoried = c
        else
          specific_to_delete = @physical_object.specific
          new_one = blank_specific_po(medium_value_from_params)
          new_one.acting_as = @physical_object.acting_as
          @physical_object.specific.actable = new_one
          @physical_object.specific.actable_type = new_one.class.to_s
          new_one.save
          specific_to_delete.delete
          @physical_object = new_one
          @physical_object.acting_as.date_inventoried = c
        end
        @nitrate = (@physical_object.is_a?(Film) && @physical_object.base_nitrate)
        # check to see if titles have changed in the update
        process_titles
        @physical_object.modifier = User.current_user_object
        @success = @physical_object.update_attributes!(physical_object_params)
      end
    rescue Exception => error
      puts error.message
      puts error.backtrace.join("\n")
      logger.debug $!
    end
    if @success
      # Filmdb no longer emails notification of nitrate base
      # if (@physical_object.is_a?(Film) && @physical_object.base_nitrate && !@nitrate)
      #   notify_nitrate(@physical_object)
      # end
      redirect_to @physical_object.acting_as, notice: 'Physical object was successfully updated.'
    else
      @original_po_id = @physical_object.acting_as.id
      set_cv
      render :edit
    end
  end

  def duplicate
    @em = 'Duplicating Physical Object'
    @physical_object = PhysicalObject.find(params[:id]).dup
    @physical_object.iu_barcode = nil
    @physical_object.reel_number = nil
    respond_to do |format|
      format.html { render 'new_physical_object', notice: 'Physical Object was successfully duplicated.' }
    end
  end

  def create_duplicate
    create_physical_object
  end

  def edit_ad_strip
    @physical_object = Film.new(medium: 'Film')
    set_cv
  end

  def update_ad_strip
    bc = params[:physical_object][:iu_barcode]
    adv = params[:physical_object][:ad_strip]
    @physical_object = PhysicalObject.where(iu_barcode: bc).first
    if @physical_object.nil?
      flash[:warning] = "No Physical Object with Barcode #{bc} Could Be Found!".html_safe
    elsif @physical_object.specific.class != Film
      flash[:warning] = "#{bc} is a #{@physical_object.specific.class}, not a Film"
    else
      set_cv
      nitrate = @physical_object.specific.base_nitrate
      @physical_object.specific.update_attributes(ad_strip: adv)
      flash[:notice] = "Physical Object [#{bc}] was updated with AD Strip Value: #{adv}"
      # Filmdb no longer emails notification about nitrate
      # if @physical_object.specific.base_nitrate && !nitrate
      #   notify_nitrate(@physical_object)
      # end
    end
    redirect_to edit_ad_strip_path
  end

  def mark_missing
    if @physical_object.current_workflow_status.status_name == WorkflowStatus::PULL_REQUESTED
      ws = WorkflowStatus.build_workflow_status(WorkflowStatus::MISSING, @physical_object, true)
      @physical_object.workflow_statuses << ws
      @physical_object.save
      flash[:notice] = "#{@physical_object.iu_barcode} was successfully marked <i>Missing</i>".html_safe
      redirect_to physical_objects_path
    else
      flash[:warning] = "#{@physical_object.iu_barcode}'s workflow status must be Pull Requested to mark missing. It's current status is #{@physical_object.current_workflow_status.status_name}".html_safe
      redirect_to physical_objects_path
    end
  end

  def workflow_history
    @physical_object = PhysicalObject.find(params[:id])
  end

  # DELETE /physical_objects/1
  # DELETE /physical_objects/1.json
  def destroy
    authorize PhysicalObject
    @physical_object.destroy
    respond_to do |format|
      format.html { redirect_to physical_objects_url, notice: 'Physical object was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def ajax_show_storage
    po = PhysicalObject.where(iu_barcode: params[:iu_barcode]).first
    if po.nil?
      render text: "Could Not Find Physical Object With IU Barcode: #{params[:iu_barcode]}"
    else
      render text: "#{params[:iu_barcode]} Should Be Returned to: <b>#{(po.storage_location.blank? ? "<b><i>Object Just inventoried...</i><b>" : po.storage_location)}</b>".html_safe
    end
  end

  # and ajax call to determine if a given IU barcoded physical object exists, and belongs to the specified title
  # call should come in with iu_barcode and title_id params
  def ajax_belongs_to_title?
    po = PhysicalObject.where(iu_barcode: params[:iu_barcode]).first
    title = Title.where(id: params[:title_id]).first
    render json: [!po.nil?, (po.nil? || !po.titles.include?(title) ? false : po.id)]
  end

  def ajax_lookup_barcode
    po = PhysicalObject.find(params[:id])
    render text: po.iu_barcode
  end

  def digiprovs
    @physical_object = PhysicalObject.find(params[:id])
    @dp = Digiprov.where(physical_object_id: params[:id])
  end

  def test_email
    @success = true
    begin
      test
    rescue Exception
      logger.debug $!
      @success = false
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_physical_object
    @physical_object = PhysicalObject.find(params[:id]).specific
  end

  def set_cv
    @cv = ControlledVocabulary.physical_object_cv(@physical_object.medium.gsub(' ', ''))
    @l_cv = ControlledVocabulary.language_cv
    @pod_cv = ControlledVocabulary.physical_object_date_cv
  end


end
