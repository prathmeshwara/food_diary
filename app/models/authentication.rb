class Authentication < ActiveRecord::Base
  attr_accessible :provider, :secret, :token, :uid, :user_id

    belongs_to :user

  # Reference: http://stackoverflow.com/questions/4673812/how-to-validate-models-with-a-composite-keys-in-activerecord
  # User should only be able to connect once to a 3rd party provider.
  # If we receive a new token when connecting to a provider with which user is
  # already associated the token should be replaced.
  validates_uniqueness_of :provider, scope: :user_id

  # This is convenience method to delete an orphan Authentication record.
  def self.find_by_provider_and_uid_with_user(provider, uid)
    authentication = Authentication.find_by_provider_and_uid(provider, uid)
    if authentication
       unless authentication.user
         authentication.delete
         authentication = nil
       end
    end
    authentication
  end

end
