#
# Cookbook Name:: github_connector
# Recipe:: upstart
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

directory "#{node['github_connector']['install_dir']}/tmp/sockets" do
  owner node['github_connector']['user']
  group node['github_connector']['group']
  mode 0755
end

template "/etc/init/github-connector-web.conf" do
  source 'upstart-github-connector-web.conf.erb'
  mode 0644
  owner 'root'
  group 'root'
  action :create
  variables(
    :home_path => "/home/#{node['github_connector']['user']}",
    :rvm_path => "/home/#{node['github_connector']['user']}/.rvm"
  )
end

template "/etc/init/github-connector-worker.conf" do
  source 'upstart-github-connector-worker.conf.erb'
  mode 0644
  owner 'root'
  group 'root'
  action :create
  variables(
    :home_path => "/home/#{node['github_connector']['user']}",
    :rvm_path => "/home/#{node['github_connector']['user']}/.rvm"
  )
end

service 'github-connector-web' do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true, :reload => true
  action :start
end

service 'github-connector-worker' do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true, :reload => false
  action :start
end
