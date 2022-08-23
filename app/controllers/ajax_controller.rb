class AjaxController < ApplicationController

  def title_physical_objects
    @title = Title.find(params[:id])
    render json: @title.physical_objects
  end

  def title_date_type
    types = ControlledVocabulary.where(model_type: 'TitleDate', model_attribute: ':date_type').where("value like #{ActiveRecord::Base.connection.quote("%#{params[:term]}%")}").order('value ASC').pluck(:value).uniq.to_json
    render json: types
  end
  def title_creator_role
    roles = ControlledVocabulary.where(model_type: 'Title', model_attribute: ':title_creator_role_type').where("value like #{ActiveRecord::Base.connection.quote("%#{params[:term]}%")}").order('value ASC').pluck(:value).uniq.to_json
    render json: roles
  end
  def title_publisher_role
    roles = ControlledVocabulary.where(model_type: 'Title', model_attribute: ':title_publisher_role_type').where("value like #{ActiveRecord::Base.connection.quote("%#{params[:term]}%")}").order('value ASC').pluck(:value).uniq.to_json
    render json: roles
  end
  def title_form
    forms = ControlledVocabulary.where(model_type: 'TitleForm', model_attribute: ':form').where("value like #{ActiveRecord::Base.connection.quote("%#{params[:term]}%")}").order('value ASC').pluck(:value).uniq.to_json
    render json: forms
  end
  def title_genre
    genres = ControlledVocabulary.where(model_type: 'TitleGenre', model_attribute: ':genre').where("value like #{ActiveRecord::Base.connection.quote("%#{params[:term]}%")}").order('value ASC').pluck(:value).uniq.to_json
    render json: genres
  end
  def title_original_identifier
    roles = ControlledVocabulary.where(model_type: 'Title', model_attribute: ':title_original_identifier_type').where("value like #{ActiveRecord::Base.connection.quote("%#{params[:term]}%")}").order('value ASC').pluck(:value).uniq.to_json
    render json: roles
  end


end
