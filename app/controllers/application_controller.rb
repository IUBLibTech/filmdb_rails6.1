class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include SessionsHelper
  include Pundit

  before_action :signed_in_user

  around_filter :scope_current_username
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def public_home

  end

  def page_link_path(page)
    physical_objects_path(page: page, status: params[:status], digitized: params[:digitized])
  end
  def physical_object_specific_path
    @physical_object.medium.downcase.parameterize.underscore
  end
  def physical_object_specific_medium
    @physical_object.nil? ? '' : @physical_object.medium.downcase.parameterize.underscore
  end
  helper_method :page_link_path
  helper_method :physical_object_specific_medium
  helper_method :physical_object_specific_path

  # This method simplifies a Physical Object params hash passed in through form submission, replacing the format specific
  # hash keys with a :physical_object key so that existing code does not need to be modified, only a call to this method
  # invoked prior to processing the hash. This is necessary because when a form is build around a specific subclass of
  # PhysicalObject, the form builds the has based on the subclass: @physical_object = Film.new and form_for(@physical_object)
  # results in params with key :film. Most of the existing code (when multiple format support was implemented) generalizes to
  # PhysicalObject.
  def acting_as_params
    params[:physical_object] = params.delete(:video) if params[:video]
    params[:physical_object] = params.delete(:film) if params[:film]
  end

  private
  def scope_current_username
    User.current_username = current_username
    yield
  ensure
    User.current_username = nil
  end

  def user_not_authorized(exception)
    flash[:warning] = "You are not authorized to #{meaningful_action_name(action_name).humanize.downcase} #{controller_name.humanize.split.map(&:capitalize)*' '}"
    redirect_to request.referrer || root_path
  end

  def meaningful_action_name(name)
    name == 'index' ? 'View' : (name == 'destroy' ? 'Delete' : name)
  end



  # def update_user_loc
  #   if session[:username]
		#   @user = User.where(username: session[:username]).first
		#   if (@user.works_in_both_locations && (@user.updated_at + SessionsHelper::TIME_OUT < Time.now)) || (!@user.works_in_both_locations && @user.worksite_location.blank?)
		# 	  session[:return_to] = request.fullpath
		# 	  redirect_to show_worksite_location_path(@user.id)
		#   end
  #   end
  # end
end
