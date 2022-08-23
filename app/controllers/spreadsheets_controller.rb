class SpreadsheetsController < ApplicationController
  require 'csv_parser'
  before_action :set_spreadsheet, only: [:show, :edit, :update, :destroy, :merge_title_candidates, :merge_series_candidates, :merge_series, :merge_series_titles, :merge_titles]

  # GET /spreadsheets
  # GET /spreadsheets.json
  def index
    @spreadsheets = Spreadsheet.all.order("id DESC")
    @file = ""
  end

  # GET /spreadsheets/1
  # GET /spreadsheets/1.json
  def show
    @physical_objects = @spreadsheet.physical_objects
    @users = User.where(created_in_spreadsheet: @spreadsheet.id)
    @series_count = Series.where(spreadsheet_id: @spreadsheet.id).group('title').count

    # need to calculate what distinct titles and series titles appear in the spreadsheet and also outside it
    @title_count_in_spreadsheet = Title.title_text_count_in_spreadsheet(@spreadsheet.id)
    @title_count_not_in_spreadsheet = Title.title_text_count_not_in_spreadsheet(@spreadsheet.id)
    @series_count_in_spreadsheet = Series.series_title_count_in_spreadsheet(@spreadsheet.id)
    @series_count_not_in_spreadsheet = Series.series_title_count_not_in_spreadsheet(@spreadsheet.id)
  end

  # DELETE /spreadsheets/1
  # DELETE /spreadsheets/1.json
  def destroy
    authorize Spreadsheet
    @spreadsheet.physical_objects.destroy_all
    @spreadsheet.titles.destroy_all
    @spreadsheet.series.destroy_all
    @spreadsheet.created_users.destroy_all
    @spreadsheet.destroy

    respond_to do |format|
      format.html { redirect_to spreadsheets_url, notice: 'Spreadsheet was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # POST /spreadsheets/upload
  def upload
    @file = params[:xls_file]
    respond_to do |format|
      if @file.blank?
        format.html { redirect_to spreadsheets_path, notice: 'You must specify an inventory file.'}
      else
        # check filename
        ss = Spreadsheet.where(filename: @file.original_filename).first
        if !ss.nil? and ss.successful_upload
          format.html { redirect_to spreadsheets_path, notice: "#{@file.original_filename} has already been uploaded successfully" }
        else
          if ss.nil?
            ss = Spreadsheet.new(filename: @file.original_filename)
            ss.save
          end
          sss = SpreadsheetSubmission.new(spreadsheet_id: ss.id)
          sss.save
          parser = CsvParser.new(@file, ss, sss)
          parser.parse_csv
          format.html { redirect_to spreadsheets_path, notice: "#{@file.original_filename} has been submitted. Please refresh the page to monitor progress." }
        end
      end
    end
  end

  def merge_series_candidates
    @series_candidates = Series.series_in_spreadsheet(Series.find(params[:series].to_i).title, @spreadsheet.id)
    @existing_series = Series.series_not_in_spreadsheet(Series.find(params[:series].to_i).title, @spreadsheet.id)
  end

  def merge_series
    respond_to do |format|
      @master = Series.find(params[:master])
      @mergees = Series.where(id: params[:selected].split(','))
      @mergees.each do |s|
        if @master.summary.blank?
          @master.summary = s.summary unless s.summary.blank?
        else
          @master.summary += " | #{s.summary}" unless s.summary.blank?
        end
        # what to do with series dates, total episodes, and series production number if they differ across merge candidates?

        s.titles.each do |t|
          t.update_attributes(series_id: @master.id)
        end
        s.delete
      end
      @master.save
      @series = @master
      @title_count_in_series = Title.title_text_count_in_series(@master.id)
      @title_count_not_in_series = Title.title_text_count_not_in_series(@master.id)
      format.html {redirect_to spreadsheet_path(id: @spreadsheet.id), notice: "#{@mergees.size + 1} Series Were Successfully Mmerged"}
    end
  end

  def merge_series_titles

  end

  # action which lists matching titles (by title text) for a given spreadsheet id
  def merge_title_candidates
	  tt = Title.find(params[:title]).title_text
    @title_candidates = Title.titles_in_spreadsheet(tt, @spreadsheet.id)
    @existing_titles = Title.titles_not_in_spreadsheet(tt, @spreadsheet.id)
  end

  # processes the form submission fomr #merge_conditate view
  def merge_titles
    respond_to do |format|
      @master_title = Title.find(params[:master])
      @mergees = Title.where(id: params[:selected].split(','))
      @mergees.each do |m|
        m.series_id = @master_title.series_id

        # if @master_title.summary is nil then += will fail as there is no += operator or nil...
        @master_title.summary = '' if @master_title.summary.blank?
        unless m.summary.blank?
          @master_title.summary = "" if @master_title.summary.blank?
          @master_title.summary += " | #{m.summary}"
        end
        unless m.series_part.blank?
          @master_title.series_part = "" if @master_title.series_part.blank?
          @master_title.series_part += (@master_title.series_part.blank? ? m.series_part : " | #{m.series_part}")
        end
        unless m.notes.blank?
          @master_title.notes = "" if @master_title.notes.blank?
	        @master_title.notes += (@master_title.notes.blank? ? m.notes : " | #{m.notes}")
        end
        unless m.subject.blank?
          @master_title.subject = "" if @master_title.subject.blank?
          @master_title.subject += (@master_title.subject.blank? ? m.subject : " | #{m.subject}")
        end

        m.title_original_identifiers.each do |toi|
          unless @master_title.title_original_identifiers.include? toi
            @master_title.title_original_identifiers << toi
          end
        end
        m.title_creators.each do |tc|
          unless @master_title.title_creators.collect.include? tc
            @master_title.title_creators << tc
          end
        end
        m.title_publishers.each do |tp|
          unless @master_title.title_publishers.collect.include? tp
            @master_title.title_publishers << tp
          end
        end
        m.title_forms.each do |tf|
          unless @master_title.title_forms.collect.include? tf
            @master_title.title_forms << tf
          end
        end
        m.title_genres.each do |tg|
          unless @master_title.title_genres.collect.include? tg
            @master_title.title_genres << tg
          end
        end
        m.title_dates.each do |td|
          unless @master_title.title_dates.collect.include? td
            @master_title.title_dates << td
          end
        end
        m.title_locations.each do |tl|
          unless @master_title.title_locations.collect.include? tl
            @master_title.title_locations << tl
          end
        end
        m.component_groups.each do |cg|
          cg.group_summary += " [* This component group belonged to another title pre-merge *] "
          cg.title = @master_title
          cg.save
        end
        PhysicalObjectTitle.where(title_id: m.id).update_all(title_id: @master_title.id)
        m.delete
      end
      @master_title.save
      # renamed so that the renderer of title knows what to render
      @title = @master_title
      format.html { redirect_to spreadsheet_path(id: @spreadsheet.id), notice: "#{@mergees.size + 1} Titles Were Successfully Merged." }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_spreadsheet
      @spreadsheet = Spreadsheet.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def spreadsheet_params
      params.fetch(:spreadsheet, {})
    end
end
