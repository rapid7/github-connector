#
# Cookbook Name:: github_connector
# Recipe:: database
#
# Copyright (C) 2014 Brandon Turner
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'postgresql::server'
include_recipe 'database::postgresql'


postgresql_connection_info = {
  :host => "localhost",
  :port => node['postgresql']['config']['port'],
  :username => 'postgres',
  :password => node['postgresql']['password']['postgres']
}

# Create database user
postgresql_database_user 'github-connector-database-user' do
  connection postgresql_connection_info
  username node['github_connector']['db']['user']
  password GithubConnector::Helpers.database_password(node)
end

# Create database
postgresql_database 'github-connector-database' do
  connection postgresql_connection_info
  database_name node['github_connector']['db']['name']
  owner node['github_connector']['db']['user']
end
