default['nginx']['default_site_enabled'] = false

default['github_connector']['http']['host_name'] = node['fqdn']
default['github_connector']['http']['host_aliases'] = []
default['github_connector']['http']['port'] = 80
default['github_connector']['http']['ssl']['port'] = 443
default['github_connector']['http']['ssl']['enabled'] = true

# The cert databag should have `cert` and `key` keys
default['github_connector']['http']['ssl']['cert_databag'] = 'github_connector'
default['github_connector']['http']['ssl']['cert_databag_item'] = 'ssl_cert'
