#
# Cookbook Name:: github_connector
# Recipe:: ruby
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

# gawk is needed to install ruby 2.1.x but is not installed by RVM
package 'gawk'

node.default['rvm']['user_installs'] = [{
  user: node['github_connector']['user'],
  home: "/home/#{node['github_connector']['user']}",
  upgrade: node['rvm']['version']
}]
include_recipe 'rvm::user'

rvm_gemset node['github_connector']['ruby_gemset'] do
  user node['github_connector']['user']
  ruby_string node['github_connector']['ruby_version']
end
