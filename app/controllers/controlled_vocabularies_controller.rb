class ControlledVocabulariesController < ApplicationController
  before_action :get_map, only: [:index, :create]
  # GET /controlled_vocabularies
  # GET /controlled_vocabularies.json
  def index
    authorize ControlledVocabulary
    @cv = ControlledVocabulary.new
  end

  def create
    authorize ControlledVocabulary
    model_type = ControlledVocabulary.where(model_attribute: params[:controlled_vocabulary][:model_attribute]).pluck(:model_type).uniq.first
    cv = ControlledVocabulary.new(model_type: model_type, model_attribute: params[:controlled_vocabulary][:model_attribute], value: params[:controlled_vocabulary][:value], active_status: true)
    cv.save!
    flash[:notice] = "The new #{model_type == 'Title' ? ControlledVocabulary.human_attribute_name(cv.model_attribute) : model_type.gsub("Title", '')} term <i>#{cv.value}</i> was created.".html_safe
    @cv = ControlledVocabulary.new
    get_map
    render :index
  end


  private
  def get_map
    @map = {}
    ControlledVocabulary.where("model_type like 'Title%'").pluck(:model_type).uniq.each do |mt|
      ControlledVocabulary.where(model_type: mt).pluck(:model_attribute).uniq.each do |ma|
        @map[ma] = ControlledVocabulary.where(model_type: mt, model_attribute: ma).order(:value).pluck(:value)
      end
    end
  end

end
