default['github_connector']['ruby_version'] = 'ruby-3.0.2'
default['github_connector']['ruby_gemset'] = 'github-connector'
default['github_connector']['rvm_alias'] = 'github-connector'

default['rvm']['version'] = '1.29.12'
default['rvm']['user_rubies'] = [node['github_connector']['ruby_version']]
default['rvm']['user_default_ruby'] = node['github_connector']['ruby_version']
default['rvm']['user_autolibs'] = 'read-fail'
