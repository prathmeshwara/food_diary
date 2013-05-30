class UsersController < ApplicationController

  before_filter :require_user, except: [:welcome]

  def welcome
  end

  def index
  end

end
