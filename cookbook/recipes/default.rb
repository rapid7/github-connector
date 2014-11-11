#
# Cookbook Name:: github_connector
# Recipe:: default
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

include_recipe 'apt'

package 'git'

include_recipe 'github_connector::user'
include_recipe 'github_connector::ssh'
include_recipe 'github_connector::database'
include_recipe 'github_connector::ruby'
include_recipe 'github_connector::server'
