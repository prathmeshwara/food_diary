class PersonalInformation < ActiveRecord::Base
  attr_accessible :age, :first_name, :gender, :last_name, :middle_name
  attr_accessible :user_id

  belongs_to :user

end
