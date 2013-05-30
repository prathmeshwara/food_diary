class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  # attr_accessible :title, :body

  # The :twitter_uid attribute is deliberately added to work around a scenario
  # wherein when a User tries to link log in via Twitter.
  # Twitter, in Omniauth Response, doesn't return the email address associated
  # with the Twitter account the user is trying to login via.
  # While creating a new user in the system when a new user first time tries to
  # login via Twitter in the application there occurs no problem.
  # But the problem occurs when a user wants to unlink his Twitter account
  # from the application.In the latter case only the record from
  # AUTHENTICATIONS table is deleted to unlink the user's linked Twitter account
  # from the application, however record in USERS table stay intact else how
  # the user will be able to login to the application.
  # Now sometime later if the user tries to again link his Twitter account
  # the application identifies him/her as a new user as there is no way
  # to identify that the user trying to login via Twitter account is already
  # registered with the application.
  # If Twitter would have been returning the email address then it could be
  # used to set as the email address of the new user created in the system
  # when the new user first time tried to login via twitter and later when
  # s/he has unliked his twitter account and wanted to relink the account.
  # Thus there is no unique identity available to validate whether the user
  # has already registered us earlier via Twitter and unlinked and want to
  # relink his account.
  # Note: The twitter_uid is not intended to be set when a user is updated or
  # created.Rather it should be updated only when unlinking the user's
  # linked Twitter account.

  has_one :personal_information, dependent: :delete
  has_many :authentications, dependent: :delete_all

  def apply_omniauth(omniauth)
    user_info_hash = omniauth[:user_info]

    unless user_info_hash.empty?
      self.email = user_info_hash[:email]
      personal_info = self.build_personal_information if !self.personal_information.present?
      personal_info.first_name = user_info_hash[:first_name]
      personal_info.last_name = user_info_hash[:last_name]

      # case omniauth[:provider]
        # when 'twitter'
      # end
    end
  end

  def twitter_account_linked?
    !authentications.find_by_provider("twitter").nil?
  end

  def name
    personal_info = self.personal_information
    unless personal_info.nil?
      first_name = personal_info.first_name
      last_name = personal_info.last_name
    end

    if (first_name.present? and last_name.present?)
      [first_name, last_name].join(" ")
    elsif first_name.present?
      first_name
    else
      self.email
    end
  end

end
