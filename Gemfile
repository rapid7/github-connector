source 'https://rubygems.org'

gem 'rails', '~> 4.2.5.1'

gem 'autoprefixer-rails'
gem 'bootstrap-sass'
gem 'coffee-rails', '~> 4.0.0'
gem 'compass-rails'
gem 'daemons'
gem 'delayed_job_active_record'
gem 'devise', '>= 3.4.0'
gem 'devise_ldap_authenticatable', '> 0.8.1'
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
