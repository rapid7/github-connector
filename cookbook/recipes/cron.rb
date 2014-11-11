#
# Cookbook Name:: github_connector
# Recipe:: cron
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

cron 'github-connector-cron' do
  user node['github_connector']['user']
  minute 56
  hour '*/4'
  home "/home/#{node['github_connector']['user']}"
  command "cd \"#{node['github_connector']['install_dir']}\" && /home/#{node['github_connector']['user']}/.rvm/bin/rvm #{node['github_connector']['rvm_alias']} do rake github:transition_users RAILS_ENV=production >> \"#{node['github_connector']['install_dir']}/log/cron.log\""
end
