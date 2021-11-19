source 'https://rubygems.org'

gem 'rails'

gem 'autoprefixer-rails'
gem 'bootstrap-sass'
gem 'coffee-rails'
gem 'compass-rails', '~> 4.0.0'
gem 'daemons'
gem 'delayed_job_active_record'
gem 'devise'
gem 'devise_ldap_authenticatable'
gem 'friendly_id'
gem 'font-awesome-rails'
gem 'jquery-rails'
gem 'oauth2'
gem 'octokit'
gem 'pg'
gem 'puma'
gem 'sanitize'
gem 'sass-rails'
gem 'state_machines-activerecord'
gem 'turbolinks'
gem 'uglifier'

# Add local customizations via rails engines
require 'pathname'
engines_path = Pathname.new(__FILE__).parent.join('vendor', 'engines')
if engines_path.exist?
  engines_path.each_child(false) do |engine_name|
    gem engine_name.to_s, path: File.join('vendor', 'engines', engine_name)
  end
end

group :development do
  gem 'foreman'
  gem 'spring'
  gem 'mini_racer'
  gem 'yard'
end

group :development, :test do
  gem 'database_cleaner'
  gem 'rspec-rails'
  gem 'rails-controller-testing'
end

group :test do
  gem 'simplecov', :require => false
  gem 'factory_bot'
end
