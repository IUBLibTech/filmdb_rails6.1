module SessionsHelper
  TIME_OUT = 15.minutes

  def sign_in(username)
    self.current_username = username
  end

  def current_username=(username)
    session[:username] = username
  end

  def current_username
    session[:username]
  end

  def current_username?(username)
    session[:username] == username
  end

  # provided for compatibility with pundit
  def current_user
    session[:username]
  end

  def signed_in_user
	  if signed_in?
		  @user = User.where(username: session[:username]).first
		  if (@user.works_in_both_locations && (@user.updated_at.localtime + SessionsHelper::TIME_OUT < Time.now.localtime)) || (!@user.works_in_both_locations && @user.worksite_location.blank?)
			  store_location
			  redirect_to show_worksite_location_path(@user.id)
		  end
		  @user.touch
	  else
		  store_location
		  redirect_to signin_url
	  end
    # unless signed_in?
    #   store_location
    #   redirect_to signin_url
    # end
  end

  def signed_in?
    !current_username.nil?
  end

  def sign_out
    self.current_username = nil
  end

  def store_location
    session[:return_to] = request.url if request.get?
  end
  
  def redirect_back_or_to(default=root_url)
    redirect_to(session[:return_to] || default)
    session.delete(:return_to)
  end
end
