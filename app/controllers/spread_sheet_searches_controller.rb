class SpreadSheetSearchesController < ApplicationController
  require "axlsx"
  before_action :set_spread_sheet_search, only: [:show, :edit, :update, :destroy]

  def index
    @spread_sheet_searches = SpreadSheetSearch.where(created_at: DateTime.now-2.days..DateTime.now)
  end

  def check_progress
    @results = SpreadSheetSearch.all.pluck(:id, :percent_complete)
    render json: @results.to_json
  end

  def destroy
    @spread_sheet_search.destroy
    respond_to do |format|
      format.html { redirect_to spread_sheet_searches_url, notice: 'Spread sheet search was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def download
    @sss = SpreadSheetSearch.find(params[:id])
    send_file "#{Rails.root}/#{@sss.file_location}"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_spread_sheet_search
      @spread_sheet_search = SpreadSheetSearch.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def spread_sheet_search_params
      params.fetch(:spread_sheet_search, {})
    end
end
