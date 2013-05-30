source 'https://rubygems.org'

gem 'rails', '3.2.9'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# To fix the warning: SECURITY WARNING: No secret option provided to Rack::Session::Cookie
# when server is started.
# Fix References:
#   1) https://makandracards.com/makandra/13580-fix-warning-no-secret-option-provided-to-rack-session-cookie
#   2) http://stackoverflow.com/questions/14191053/error-security-warning-no-secret-option-provided-to-racksessioncookie
gem 'rack', '1.4.1'

gem "rails_config", "~> 0.3.3"
gem "haml", ">= 3.1.5"
gem "haml-rails", ">= 0.3.4"
gem "kaminari", "~> 0.14.1"
gem "devise", "~> 2.2.4"

gem "omniauth", "~> 1.1.4"
gem "omniauth-twitter", "~> 0.0.16"
gem "paperclip", "~> 3.4.2"
gem "aws-sdk", "~> 1.11.0"

group :development do
  gem 'sqlite3'
  gem 'mysql2', '~> 0.3.11'
end

group :production do
  gem 'pg'
end


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'coffee-rails', '~> 3.2.1'
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'
# https://github.com/anjlab/bootstrap-rails/issues/35
gem 'sass-rails', '~> 3.2'
gem 'bootstrap-sass', '~> 2.3.1.2'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'
