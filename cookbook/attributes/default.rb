default['github_connector']['user'] = 'github'
default['github_connector']['group'] = node['github_connector']['user']
default['github_connector']['install_dir'] = '/var/www/github-connector'

default['github_connector']['repo']['url'] = 'https://github.com/rapid7/github-connector.git'
default['github_connector']['repo']['revision'] = 'v0.1.2'

# The secrets databag can contain the following keys:
#   * database_password
#   * database_key
#   * secrets_key_base
default['github_connector']['secrets_databag'] = 'github_connector'
default['github_connector']['secrets_databag_item'] = 'secrets'
default['github_connector']['secrets'] = {}
