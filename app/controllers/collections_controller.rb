class CollectionsController < ApplicationController
  include PhysicalObjectsHelper
  include CollectionInventoryConfigurationsHelper

  before_action :set_collection, only: [:show, :edit, :update, :destroy, :new_physical_object, :create_physical_object]
  before_action :init_create_physical_object, only: [:new_physical_object, :create_physical_object]

  # GET /collections
  # GET /collections.json
  def index
    @collections = Collection.all.order(:name)
  end

  # GET /collections/1
  # GET /collections/1.json
  def show
  end

  # GET /collections/new_physical_object
  def new
    @collection = Collection.new
  end

  # GET /collections/1/edit
  def edit
  end

  # POST /collections
  # POST /collections.json
  def create
    @collection = Collection.new(collection_params)
    respond_to do |format|
      if @collection.save
        config.save
        format.html { redirect_to action: 'index', notice: 'Collection was successfully created.' }
        format.json { render :show, status: :created, location: @collection }
      else
        format.html { render :new_physical_object }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /collections/1
  # PATCH/PUT /collections/1.json
  def update
    respond_to do |format|
      if @collection.update(collection_params)
        format.html { render :show, notice: 'Collection was successfully updated.' }
        format.json { render :show, status: :ok, location: @collection }
      else
        format.html { render :edit }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /collections/1
  # DELETE /collections/1.json
  def destroy
    authorize Collection
    @collection.destroy
    respond_to do |format|
      format.html { redirect_to collections_url, notice: 'Collection was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # def new_physical_object
  #   @em = 'Creating New Physical Object'
  #   render "physical_objects/new_physical_object"
  # end

  def autocomplete_collection
    if params[:term]
      json = Collection.joins(:unit).where("collections.name like ?", "%#{params[:term]}%").select('collections.id, collections.name, unit_id, units.abbreviation').to_json
      json.gsub! "\"name\":", "\"label\":"
      json.gsub! "\"id\":", "\"value\":"
      render json: json
    else
      render json: ""
    end
  end

  def autocomplete_collection_for_unit
    if params[:term]
      json = Collection.joins(:unit).where("collections.name like ? AND unit_id = ?", "%#{params[:term]}%", "#{params[:unit_id]}").select('collections.id, collections.name, unit_id, units.abbreviation').to_json
      json.gsub! "\"name\":", "\"label\":"
      json.gsub! "\"id\":", "\"value\":"
      render json: json
    else
      render json: ""
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_collection
      @collection = Collection.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def collection_params
      params.require(:collection).permit(
        :name, :unit_id, :summary, :accessible, :accessible_notes, :current_ownership_and_control, :transfer_of_ownership
      )
    end

end
