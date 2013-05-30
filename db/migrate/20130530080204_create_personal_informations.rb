class CreatePersonalInformations < ActiveRecord::Migration
  def self.up
    create_table :personal_informations do |t|
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.integer :age
      t.string :gender
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :personal_informations
  end

end
