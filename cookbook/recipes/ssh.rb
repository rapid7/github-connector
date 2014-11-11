#
# Cookbook Name:: github_connector
# Recipe:: ssh
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

if node['github_connector']['ssh_databag'] && node['github_connector']['ssh_databag_item']
  ssh_data_bag = GithubConnector::Helpers.load_data_bag(
    node['github_connector']['ssh_databag'],
    node['github_connector']['ssh_databag_item']
  )

  if ssh_data_bag && ssh_data_bag['private_key']
    require 'net/ssh'
    private_key = OpenSSL::PKey::RSA.new(ssh_data_bag['private_key'])
    public_key = private_key.public_key
    ssh_dir = "/home/#{node['github_connector']['user']}/.ssh"

    directory ssh_dir do
      mode 0700
      owner node['github_connector']['user']
      group node['github_connector']['group']
    end

    file ::File.join(ssh_dir, 'github_connector_id_rsa') do
      content private_key.to_pem
      owner node['github_connector']['user']
      group node['github_connector']['group']
      mode 0600
    end

    file ::File.join(ssh_dir, 'github_connector_id_rsa.pub') do
      content "#{public_key.ssh_type} #{[public_key.to_blob].pack('m0')}\n"
      owner node['github_connector']['user']
      group node['github_connector']['group']
      mode 0644
    end

    file ::File.join(ssh_dir, 'github_connector_ssh_wrapper.sh') do
      content "#!/bin/sh -e\nexec ssh -i #{::File.join(ssh_dir, 'github_connector_id_rsa')} $@\n"
      owner node['github_connector']['user']
      group node['github_connector']['group']
      mode 0755
    end
  end
end

if node['github_connector']['github_host_key']
  ssh_known_hosts_entry 'github.com' do
    key node['github_connector']['github_host_key']
  end
end
