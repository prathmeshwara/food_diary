class Diet < ActiveRecord::Base
  attr_accessible :description, :logger_id, :name
  # Reference: https://github.com/thoughtbot/paperclip#readme --> "Quick Start"
  attr_accessible :photo
  attr_accessible :photo_file_name, :photo_content_type, :photo_file_size

  # The default place to store attachments is in the filesystem
  # References:
  # 1) http://rdoc.info/github/thoughtbot/paperclip/Paperclip/Storage/Filesystem
  # 2) https://github.com/thoughtbot/paperclip#readme --> "Understanding Storage"
  # 3) http://stackoverflow.com/questions/2562249/how-can-i-set-paperclips-storage-mechanism-based-on-the-current-rails-environme
  paperclip_options = {
    styles: {
      medium: "#{Settings.photos.diet.styles.medium}>",
      thumb: "#{Settings.photos.diet.styles.thumb}>"
    },
    default_url: Settings.photos.diet.default_image_path
  }

  paperclip_options = Paperclip::Attachment.default_options.merge(paperclip_options)
  has_attached_file :photo, paperclip_options

  # Paperclip Validations
  validates_attachment :photo, content_type: { content_type: /image/ }, size: { in: (0..10000.kilobytes) }

  belongs_to :logger, class_name: 'User'

end
