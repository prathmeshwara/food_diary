class UsersController < ApplicationController

  before_filter :require_user, except: [:welcome]

  def welcome
    redirect_to user_home_path if user_signed_in?
  end

  def index
  end

end
