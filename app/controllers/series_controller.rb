class SeriesController < ApplicationController
  include PhysicalObjectsHelper
  before_action :set_series, only: [:show, :edit, :update, :destroy, :ajax_summary]

  # GET /series
  # GET /series.json
  def index
    @series = Series.all.order(:title)
  end

  # GET /series/1
  # GET /series/1.json
  def show
  end

  # GET /series/new_physical_object
  def new
    @series = Series.new(created_by_id: User.current_user_object.id, modified_by_id: User.current_user_object.id)
  end

  # GET /series/1/edit
  def edit
    @series.modified_by_id = User.current_user_object.id
  end

  # POST /series
  # POST /series.json
  def create
    # Series form passes in a series title string that needs to be mapped
    @series = Series.new(series_params)
    respond_to do |format|
      if @series.save
        format.html { redirect_to @series, notice: 'Series was successfully created.' }
        format.json { render :show, status: :created, location: @series }
      else
        format.html { render :new_physical_object }
        format.json { render json: @series.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /series/1
  # PATCH/PUT /series/1.json
  # noinspection RubyArgCount
  def update
    respond_to do |format|
      if @series.update(series_params)
        format.html { redirect_to @series, notice: 'Series was successfully updated.' }
        format.json { render :show, status: :ok, location: @series }
      else
        format.html { render :edit }
        format.json { render json: @series.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /series/1
  # DELETE /series/1.json
  # noinspection RubyArgCount
  def destroy
    authorize Series
    @series.destroy
    respond_to do |format|
      format.html { redirect_to series_index_url, notice: 'Series was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def show_merge_series
  end

  def ajax_show_series
    @series = Series.find(params[:id])
    render partial: 'ajax_show_series'
  end

  def ajax_series_merge_table_row
    @series = Series.find(params[:id])
    render partial: 'ajax_series_merge_table_row'
  end

  def new_physical_object
    @em = 'Creating New Physical Object'
    @physical_object = PhysicalObject.new
    render 'physical_objects/new_physical_object'
  end

  def autocomplete_series
    if params[:term]
      if params[:exclude]
        @series = Series.where("title like ? AND series.id not in (?)", "%#{params[:term]}%", params[:exclude]).select('id, title')
      else
        @series = Series.where("title like ? ", "%#{params[:term]}%").select('id, title, summary')
      end
      json = @series.to_json
      json.gsub! "\"title\":", "\"label\":"
      json.gsub! "\"id\":", "\"value\":"
      render json: json
    else
      render json: ""
    end
  end

  def series_auto_complete_selection_merge
    @master = Series.find(params[:master_series_id])
    @mergees = Series.where("id in (?)", params[:mergees].split(',').collect{ |s| s.to_i})
    begin
      Series.transaction do
        @mergees.each do |s|
          s.titles.each do |t|
            t.update_attributes!(series_id: @master.id)
          end
          if !s.production_number.blank? && @master.production_number != s.production_number
            @master.production_number += " | #{s.production_number}"
          end
          if !s.date.blank? && @master.date != s.date
            @master.date += " | #{s.date}"
          end
          if !s.summary.blank? && @master.summary != s.summary
            @master.summary += " | #{s.summary}"
          end
          s.destroy
        end
        if @master.changed?
          @master.save!
        end
      end
      flash[:notice] = "#{@mergees.size} other Series #{@mergees.size > 1 ? "were" : "was"} merged into this Series."
    rescue ActiveRecord::RecordNotFound => e
      flash[:warning] = "An error occurred, the merge was unsuccessful. No changes have been made to the database."
    end
    redirect_to series_path(@master)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_series
      @series = Series.find(params[:id])
      @cv = ControlledVocabulary.physical_object_cv('Film')
      @l_cv = ControlledVocabulary.language_cv
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def series_params
      params.require(:series).permit(:title, :summary, :created_by_id, :modified_by_id, :production_number, :total_episodes, :date)
    end
end
