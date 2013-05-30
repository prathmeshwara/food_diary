require 'diary/auth/omniauth_helper'

# Reference: https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  include Diary::Auth::OmniauthHelper

  # The callback should be implemented as an action with the same name as the
  # provider.Its required by Devise to work in a correct manner.
  def twitter
    handle_callback(:twitter)
  end

  # DELETE /users/auth/:provider/disconnect
  def disconnect
    handle_disconnect(params[:provider])
  end

end
