name             'github_connector'
maintainer       "Rapid7, Inc."
maintainer_email "engineeringservices@rapid7.com"
license          "Apache v2.0"
description      "Installs and configures the GitHub Active Directory Connector"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.1"

supports 'ubuntu'

depends 'apt', '>= 2.3.10'
depends 'database', '>= 2.0'
depends 'logrotate', '>= 1.7.0'
depends 'nginx', '>= 2.0'
depends 'postgresql', '>= 3.4.0'
depends 'ssh_known_hosts'

# rvm is a rapid7 patched version, see Berksfile
depends 'rvm', '= 0.9.0'
