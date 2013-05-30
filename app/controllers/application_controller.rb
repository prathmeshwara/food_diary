class ApplicationController < ActionController::Base
  protect_from_forgery

  # Reference: https://github.com/plataformatec/devise/wiki/How-to:-redirect-to-a-specific-page-on-successful-sign-in-and-sign-out
  def after_sign_in_path_for(resource)
     user_home_path
  end

  def after_sign_up_path_for(resource)
    user_home_path
  end

  private

  def require_user
    redirect_to root_path unless user_signed_in?
  end

end
