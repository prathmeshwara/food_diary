module Diary
  module Auth
    module OmniauthHelper
      def handle_callback(provider)
         omniauth = omniauth_hash(provider)

         authentication = find_authentication(omniauth)

         error_message = check_error_conditions(authentication, provider, omniauth)

         unless error_message.nil?
            if connect_existing_user?
              connecting_user = user_by_email(connecting_user_email)
              # This means logged in user tried connecting to provider from website
              redirect_to(user_home_path, alert: error_message)
            else
              # This means a new user tried to log in through provider credentials from
              # website login page.This scenario is only applicable to Facebook
              # provider as on login page "Login through: Facebook" link
              # is only available.
              redirect_to(signin_path, flash: {error: error_message})
            end

            clear_session_data # This is needed
            return
         end

         Rails.logger.debug "No error conditions met."

         # Update token and secret if received values are different from current ones
         # If we receive new details when connecting to a provider with which user
         # is already associated the details should be replaced.
         update_authentication(omniauth, authentication) unless authentication.nil?

         user = get_user(omniauth, authentication)

         user = create_new_user(omniauth, user) if user.new_record?

         if user.id.nil?
           error_message = t('omniauth.errors.user_friendly_message')
           redirect_to(signin_path, flash: {error: error_message})
           return
         end

         authentication = create_user_authentication(omniauth, user) if authentication.nil?

         if authentication.nil?
           Rails.logger.debug "Could not create authentication record for provider #{provider.capitalize} for user #{user.email}."
           error_message = t('omniauth.errors.user_friendly_message')
           redirect_to(signin_path, flash: {error: error_message})
         else
            redirect_user(user, authentication)
         end
      end

      def handle_disconnect(provider)
         authentication = Authentication.find_by_provider_and_user_id(provider.to_s, current_user.id)
         authentication.user.update_attribute(:twitter_uid, authentication.uid)
         authentication.delete
         Rails.logger.debug "Successfully disconnected #{current_user.name} from #{provider.to_s.capitalize}"
         redirect_to user_home_path, flash: { notice: t('omniauth.notices.disconnect', { user_name: current_user.name, provider: provider })}
      end

      private

      def user_connected_to_provider?(provider)
        # Devise's current_user
        Authentication.exists?(provider: provider, user_id: current_user.id)
      end

      def check_error_conditions(authentication, provider, omniauth)
         Rails.logger.debug "Checking error conditions"
         error_message = nil

         if authentication.nil?
           Rails.logger.debug "Checking error conditions - No authentication found in database for provider: #{provider} and uid: #{omniauth[:uid]}"

           if connect_existing_user?
              Rails.logger.debug "Checking error conditions - request for connecting existing user"
              if user_connected_to_provider?(provider.to_s)
                Rails.logger.debug "User [id: #{current_user.id}] already found connected to #{provider.capitalize} account."
                # This means for received uid and provider no authentication exists
                # but user connected to same provider with other account.
                error_message = t('omniauth.errors.already_connected', { provider: provider.capitalize} )
              end
           else
              # Note: Below error condition checking is being skipped for now,
              # though this checking should matter in case a user has signed
              # up with the application using email say abc@example.com
              # and say a fraud user uses the creds having same email
              # (already registered with the system, in present e.g.
              # abc@example.com) to login through Facebook feature of
              # the application.In this way the fraud user getting over Facebook
              # account can get hold of the account with the application and
              # might misuse it.Rare condition but considerable.

              # Anyways current requirement is to let the Authentication record
              # get created for the user who has already signed up with the
              # email(s/he uses to login to Facebook) in our application.In other
              # words when user is already registered with the application say
              # jignesh.gohel@example.com and tries to log in through Facebook
              # using the same email he should be transparently logged-in to
              # the application.

              # Rails.logger.debug "Checking error conditions - request for new user trying to connect with #{provider}"
              # user_email = omniauth[:user_info][:email]
              # unless user_by_email(user_email).nil?
                # Rails.logger.debug "Checking error conditions - Found a user in the system with email #{user_email} returned by #{provider}."
                # error_message = "There is already an account with email #{user_email}. Please log in with your password, and connect to your #{provider} account from the Settings page."
              # end
           end
         elsif !current_user_and_authentication_user_same?(authentication, omniauth)
           error_message = t('omniauth.errors.account_associated_with_another_user', { provider: provider.capitalize} )
         end
         error_message
      end

      def omniauth_hash(provider)
        hash = {}
        uid = nil
        token = nil
        secret = nil
        user_info = {}

        case provider
          when :facebook, :linkedin, :twitter
              omniauth = request.env['omniauth.auth']
              uid = omniauth['uid']
              credentials = omniauth['credentials']
              token = credentials['token']
              secret = credentials['secret']
              info = omniauth['info']

              user_info[:image] = info.image
              user_info[:url] = info['urls']["#{provider.to_s.capitalize}"]
              user_info[:provider_user_name] = info.nickname

              if :twitter == provider
                # Twitter doesn't return first name and last name explicitly
                user_info[:first_name] = info.name
                # Twitter doesn't return email in the oauth response.Thus using
                # a work around here.
                # Reference: http://stackoverflow.com/questions/16415200/omniauth-twitter-email-id-is-not-fetched-from-twitter-in-ruby-on-rails
                use_nickname_or_first_name_as_email = (user_info[:provider_user_name] || user_info[:first_name]).downcase.underscore
                Rails.logger.debug "Twitter doesn't return email in OAuth response thus setting the email to nickname/first name ( #{use_nickname_or_first_name_as_email} ) which must be later changed by user."
                user_info[:email] = use_nickname_or_first_name_as_email
              else
                user_info[:email] = info.email
                user_info[:first_name] = info.first_name
                user_info[:last_name] = info.last_name
              end

        end

        hash[:provider] = provider.to_s
        hash[:uid] = uid
        hash[:token] = token
        hash[:secret] = secret
        hash[:user_info] = user_info

        hash
      end

      def find_authentication(omniauth)
         provider = omniauth[:provider].to_sym
         Rails.logger.debug "Finding authentication for: #{provider}"
         authentication = Authentication.find_by_provider_and_uid_with_user(provider, omniauth[:uid])
         authentication
      end

      def update_authentication(omniauth, authentication)
         provider = omniauth[:provider].to_sym

         unless authentication.nil?
           current_token = authentication.token
           current_secret = authentication.secret
           current_uid = authentication.uid
           #current_user_name = authentication.user_name

           received_token =  omniauth[:token]
           received_secret =  omniauth[:secret]
           #received_user_name = omniauth[:user_info][:provider_user_name]

           updated_attrs = {}
           updated_attrs[:token] = received_token if ((current_token.nil?) or (current_token != received_token))
           updated_attrs[:secret] = received_secret if ((current_secret.nil?) or (current_secret != received_secret))
           #updated_attrs[:user_name] = received_user_name if ((current_user_name.nil?) or (current_user_name != received_user_name))

           unless updated_attrs.empty?
             Rails.logger.debug "Updating authentication [id: #{authentication.id}] for: #{provider}"
             authentication.update_attributes(updated_attrs)
             Rails.logger.debug "Updated attributes #{updated_attrs.keys} for authentication [id: #{authentication.id}] for: #{provider}"
           end
         end
      end

      def current_user_and_authentication_user_same?(authentication, omniauth)
        flag = true

        if authentication
          provider = omniauth[:provider]
          Rails.logger.debug "Authentication exists in the system for #{provider}'s uid."
          authentication_user = authentication.user
          if connect_existing_user?
            user_email = connecting_user_email
            Rails.logger.debug "Request is for connecting user having email #{user_email} to provider #{provider}"
            connecting_user = user_by_email(user_email)

            if (connecting_user.id != authentication_user.id)
              flag = false
              Rails.logger.debug "Could not connect user having email #{user_email} to provider #{provider}."
              Rails.logger.debug "User[id: #{authentication_user.id}, email: #{authentication_user.email}] is already found to be associated with #{provider}'s uid in the system."
            end
          end
        end

        flag
      end

      def get_user(omniauth, authentication)
         user = nil
         provider = omniauth[:provider]
         if connect_existing_user?
            user_email = connecting_user_email
            Rails.logger.debug "Request for connecting user.Returning existing user having email #{user_email}"
            user = user_by_email(user_email)
         elsif authentication
            Rails.logger.debug "Authentication already available.Returning user associated with authentication id: #{authentication.id}"
            user = authentication.user
         else
            user_email = omniauth[:user_info][:email]
            user = user_by_email(user_email)

            # Note: In case of Twitter OAuth add an attribute "twitter_uid" to
            # USERS table.This is to handle the case where in a user logs in via
            # Twitter first time and registered with the application and later
            # unlinks his Twitter account and later wants to relink the same
            # Twitter account.The reason behind adding the "twitter_uid" attribute
            # to User model is to preventing a new user being created in the system
            # who had already registered with the application using his same
            # Twitter account which he later unlinked and wants to relink it.
            if (user.nil? and (:twitter == provider.to_sym))
              twitter_uid = omniauth[:uid]
              Rails.logger.debug "Request is for Twitter auth"
              Rails.logger.debug "Could not find user by email.Finding by Twitter UID #{twitter_uid}"
              user = User.find_by_twitter_uid(twitter_uid)
              Rails.logger.debug "Found user against Twitter UID #{twitter_uid}" if user.present?
            end

            if user.nil?
              Rails.logger.debug "New user trying to sign in through #{provider}.Returning a new user instance."
              user = User.new
            else
              Rails.logger.debug "Returning existing user in the system [id: #{user.id}] having email: #{user.email}"
            end
         end
         user
      end

      def create_new_user(omniauth, user)
        if user.new_record?
          Rails.logger.debug "New user instance found.Applying omniauth details and creating the user."
          # For existing user the omniauth user details should not be applied.Those
          # should be applied only to new users signing in through external provider,
          # say facebook
          user.apply_omniauth(omniauth)

          # Password is a required field with Devise authentication framework
          # and if we don't skip validations while saving user, the save method
          # returns false which doesn't create Authenticate record for
          # the user for current provider.
          Rails.logger.debug "Skipping any validations on a new User as we are not setting any password for the new user as it is not available."
          if user.save(validate: false)
            new_user_id = user.id
            session[:new_user_created] = true
            Rails.logger.debug "Created new user [id: #{new_user_id}]."
          else
            Rails.logger.debug "Could not save new user to database trying to connect through #{omniauth[:provider].capitalize} using email #{omniauth[:user_info][:email]}."
          end
        end
        user
      end

      def create_user_authentication(omniauth, user)
        provider = omniauth[:provider]
        uid = omniauth[:uid]
        token = omniauth[:token]
        secret = omniauth[:secret]
        provider_email = omniauth[:user_info][:provider_email]
        provider_user_name = omniauth[:user_info][:provider_user_name]

        authentication = user.authentications.create!(user_id: user.id, provider: provider, uid: uid, token: token, secret: secret)
        Rails.logger.debug "Successfully created authentication for provider #{provider.capitalize} for user #{user.email}."
        authentication
      end

      def redirect_user(user, authentication)
        web_sign_in(user)
        web_redirect(user, authentication.provider)
      end

      def user_by_email(email)
        User.find_by_email(email)
      end

      def web_sign_in(user)
        # Reference: https://github.com/plataformatec/devise/wiki/How-To:-Sign-in-as-another-user-if-you-are-an-admin
        sign_in(:user, user)
      end

      def web_redirect(user, provider)
        # new_user_created? method uses session to check for user's status as
        # new or not.Thus clear_session_data must always be invoked after its
        # invocation else session data will get lost and new_user will always
        # get set to false.
        new_user = new_user_created?
        clear_session_data
        if new_user
          redirect_to edit_user_registration_path
        else
          redirect_to user_home_path
        end
      end

      def connect_existing_user?
        # When explicitly setting current_user in session and then at last
        # clear_session_data is executed in web_redirect(user, provider).
        # After redirect invoking the Devise's current_user helper returns nil
        # The reason can be following: initially
        # session[:current_user] = current_user was done and
        # then session.delete(:current_user)  which might be destroying the object.
        # Thus avoiding setting Devise's current_user returned object in session.

        # Found a similar reference here: http://stackoverflow.com/questions/7534558/current-user-devise-method-returns-nil-outside-the-user-controller
        return (current_user ? true : false)
      end

      def set_session_var(name, value)
        session[name] = value
      end

      def remove_from_session(name)
        session.delete(name) if session[name]
      end

      def clear_session_data
        remove_from_session(:auth_provider)
        remove_from_session(:new_user_created)
        Rails.logger.debug "Cleared session data for the external provider authentication requests."
      end

      def connecting_user_email
        current_user.email
      end

      def new_user_created?
        return (session[:new_user_created].present? ? true : false)
      end
    end
  end
end
