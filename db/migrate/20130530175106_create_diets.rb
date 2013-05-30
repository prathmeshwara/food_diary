class CreateDiets < ActiveRecord::Migration
  def self.up
    create_table :diets do |t|
      t.string :name
      t.string :description
      t.integer :logger_id

      t.timestamps
    end

    # Reference: https://github.com/thoughtbot/paperclip#readme
    add_attachment :diets, :photo
  end

  def self.down
    remove_attachment :diets, :photo
    drop_table :diets
  end


end
