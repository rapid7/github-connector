source 'https://rubygems.org'

gem 'rails', '~> 4.2.5'

gem 'autoprefixer-rails'
gem 'bootstrap-sass'
gem 'coffee-rails', '~> 4.0.0'
gem 'compass-rails'
gem 'daemons'
gem 'delayed_job_active_record'
gem 'devise', '>= 3.4.0'
# We can switch to upstream when version > 0.8.1 is released
# see: https://github.com/cschiewek/devise_ldap_authenticatable/pull/172
#      https://github.com/cschiewek/devise_ldap_authenticatable/pull/171
#      https://github.com/cschiewek/devise_ldap_authenticatable/pull/170
gem 'devise_ldap_authenticatable', git: 'https://github.com/blt04/devise_ldap_authenticatable.git', branch: 'patches'
gem 'friendly_id'
gem 'font-awesome-rails'
gem 'jquery-rails'
gem 'oauth2'
gem 'octokit', '> 3.3.1'
gem 'pg'
gem 'puma'
gem 'sanitize'
gem 'sass-rails', '~> 4.0'
gem 'state_machine'
gem 'turbolinks'
gem 'uglifier', '>= 1.3.0'

group :development do
  gem 'foreman'
  gem 'spring'
  gem 'therubyracer'
  gem 'yard'
end

group :development, :test do
  gem 'database_cleaner'
  gem 'rspec-rails'
end

group :test do
  gem 'simplecov', :require => false
  gem 'factory_girl_rails'
end
