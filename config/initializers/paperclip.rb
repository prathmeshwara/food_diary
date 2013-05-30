if Rails.env =~ /(development|dev)/
 # Reference: https://github.com/thoughtbot/paperclip#readme
 Paperclip.options[:command_path] = "/usr/bin"
end
