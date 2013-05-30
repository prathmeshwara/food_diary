# References:
# 1. http://stackoverflow.com/questions/11002553/unknown-action-the-action-create-could-not-be-found-for-registrationscontroll
# 2. https://github.com/plataformatec/devise/wiki/How-To:-Redirect-to-a-specific-page-on-successful-sign-up-%28registration%29
class Users::RegistrationsController < Devise::RegistrationsController

  # https://github.com/plataformatec/devise/wiki/How-To:-Allow-users-to-edit-their-account-without-providing-a-password
  def update
    @user = User.find(current_user.id)

    successfully_updated = if needs_password?(@user, params)
                                # This shall require current password to be received
                                @user.update_with_password(params[:user])
                             else
                                # Update any information email, password anything.
                                # with @user.update_attributes(params[:user])
                                # When using @user.update_without_password(params[:user])
                                # it updates other information except password.
                                @user.update_attributes(params[:user])
                             end

    if successfully_updated
      set_flash_message :notice, :updated
      # Sign in the user bypassing validation in case his password changed
      sign_in @user, :bypass => true
      redirect_to after_update_path_for(@user)
    else
      render "edit"
    end
  end

  private

  # check if we need password to update user data
  # ie if password or email was changed
  # extend this as needed
  def needs_password?(user, params)
    flag = true
    if user.encrypted_password.blank?
      flag =  false
    elsif (user.email != received_email) or ( !params[:user][:password].blank? )
      flag = true
    end

    return flag
  end

  def received_email
    params[:user][:email]
  end

end