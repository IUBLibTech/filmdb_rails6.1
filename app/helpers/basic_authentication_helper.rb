# Authentication method for BasicAuth
#
module BasicAuthenticationHelper

  protected
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == Settings.filmdb_service_username && password == Settings.filmdb_service_pass
    end
  end
end
