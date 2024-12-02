class AccompanyingDocumentationsController < ApplicationController

  before_action :set_accompanying_documentation, only: %i[ show edit update destroy ]

  PO_ASSOC = PhysicalObject
  TITLE_ASSOC = Title
  SERIES_ASSOC = Series

  # GET /accompanying_documentations or /accompanying_documentations.json
  def index
    @accompanying_documentations = AccompanyingDocumentation.all
  end

  # GET /accompanying_documentations/1 or /accompanying_documentations/1.json
  def show
  end

  # GET /accompanying_documentations/new
  def new
    @accompanying_documentation = AccompanyingDocumentation.new
  end

  # GET /accompanying_documentations/1/edit
  def edit
    @pos = @accompanying_documentation.physical_objects

  end

  # POST /accompanying_documentations or /accompanying_documentations.json
  def create
    po_ids = params[:po_ids]
    title_id = params[:title_id]
    series_id = params[:series_id]
    @accompanying_documentation = AccompanyingDocumentation.new(location: params[:accompanying_documentations][:location], description: params[:accompanying_documentations][:description])

    type = only_one?(po_ids, title_id, series_id)
    if type == TITLE_ASSOC

      @accompanying_documentation.title_id = title_id.to_i
    elsif type == SERIES_ASSOC
      @accompanying_documentation.series_id = series_id.to_i
    elsif type == PO_ASSOC
      po_ids.split(",").each do |po_id|
        po = PhysicalObject.find(po_id)
        @accompanying_documentation.physical_objects << po
      end
    else
      raise "Cannot create AccompanyingDocumentation with more than one associated object type!"
    end

    respond_to do |format|
      if @accompanying_documentation.save
        url = title_path(@accompanying_documentation.title) if type == TITLE_ASSOC
        url = series_path(@accompanying_documentation.series) if type == SERIES_ASSOC
        url = physical_object_path(@accompanying_documentation.physical_objects.first) if type == PO_ASSOC
        format.html { redirect_to url, notice: "Accompanying Documentation was successfully created." }
        format.json { render :show, status: :created, location: @accompanying_documentation }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @accompanying_documentation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /accompanying_documentations/1 or /accompanying_documentations/1.json
  def update
    respond_to do |format|
      if @accompanying_documentation.update(accompanying_documentation_params)
        format.html { redirect_to accompanying_documentation_url(@accompanying_documentation), notice: "Accompanying Documentation was successfully updated." }
        format.json { render :show, status: :ok, location: @accompanying_documentation }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @accompanying_documentation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /accompanying_documentations/1 or /accompanying_documentations/1.json
  def destroy
    @accompanying_documentation.destroy

    respond_to do |format|
      format.html { redirect_to accompanying_documentation_url, notice: "Accompanying Documentation was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_accompanying_documentation
    @accompanying_documentation = AccompanyingDocumentation.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def accompanying_documentation_params
    params.require(:accompanying_documentations).permit(:location, :description, :title_id, :series_id, :po_ids)
  end
  def only_one?(pos, title, series)
    return SERIES_ASSOC if (pos.blank? && title.blank? && !series.blank?)
    return TITLE_ASSOC if (pos.blank? && !title.blank? && series.blank?)
    return PO_ASSOC if (!pos.blank? && title.blank? && series.blank?)
    return nil
  end



end
