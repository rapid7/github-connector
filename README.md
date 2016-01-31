# GitHub Active Directory Connector

[![Build Status](https://travis-ci.org/rapid7/github-connector.svg?branch=master)](https://travis-ci.org/rapid7/github-connector)

GitHub Connector is a simple application for connecting GitHub.com organizations to
internal Active Directory accounts.  It grants access to new hires, removes access
from terminated employees, and enforces a set of GitHub membership rules.

GitHub Connector is a simple application for managing [GitHub.com organizations](https://help.github.com/categories/organizations/) using your internal Active Directory server. The Connector, an app which runs internally, allows you to:

* Automatically remove terminated employees from GitHub organization
* Audit each GiHub account for compliance with policies such as:
    * Ensure that only corporate email addresses are used for [GitHub accounts](https://developer.github.com/v3/users/emails/)
    * Ensure that [two-factor authentication](https://help.github.com/articles/about-two-factor-authentication/) is enabled for each account
* Enable one-step GitHub organization invite & acceptance for approved employees

Future feature ideas:
* Use AD group membership to control GitHub Organization and [GitHub Team](https://help.github.com/articles/adding-or-inviting-members-to-a-team-in-an-organization/) membership assignment
* Detect [duplicate/weak SSH keys](https://factorable.net/index.html) across all accounts

## Table of contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Running](#running)
- [Configuration](#configuration)
- [Synchronization](#synchornization)
- [Rules](#rules)
- [Tests](#tests)
- [Customizing](#customizing)
- [Contributing](#contributing)
- [Copyright and License](#license)

## Quick start

- Clone the repo: `git clone git://github.com/rapid7/github-connector.git`
- Run bundler: `bundle install`
- Copy `config/secrets.yml.example` to `config/secrets.yml`
- Copy `config/database.yml.example` to `config/database.yml` and update
- Create database: `rake db:create db:migrate`
- Start application: `foreman start`
- Navigate to [http://localhost:5000](http://localhost:5000)

## Installation

GitHub Connector is a Rails 4 application.  It runs on Ruby > 2.0.  All settings are stored in a PostgreSQL database.

1. Install Ruby 2.x.  We recommend [RVM](https://rvm.io/).
2. If using RVM, create a gemset: `rvm gemset create github-connector && rvm gemset use github-connector`.
3. Install required gem dependencies: `bundle install`
4. Copy the `config/secrets.yml.example` file to `config/secrets.yml`.  Generate new random secrets with `rake secret` and paste them in `config/secrets.yml`
5. Copy the `config/database.yml.example` file to `config/database.yml`.  Update the file with your database settings.
6. Create the database: `rake db:create db:migrate`

### Development Environment

#### OpenLDAP

To ease development, GitHub Connector emulates Active Directory using OpenLDAP.  In development, OpenLDAP will automatically be populated with fake data.

OpenLDAP is pre-installed on OSX.  On Linux, install OpenLDAP.  For example, on Ubuntu use:

1. Install OpenLDAP: `sudo apt-get install slapd ldap-utils`
2. Stop `slapd` as we will run our own copy: `service slapd stop`
3. Apparmor prevents us from running the OpenLDAP server with custom a configuration.  To get around this, put apparmor into complain mode: `sudo apt-get install apparmor-utils && sudo aa-complain /usr/sbin/slapd`

## Running

### Production

There are several ways to run a Rails application in production.  We include a [chef cookbook](cookbook/) that installs and
configures the GitHub Active Directory Connector.

### Development

In a development environment, use `foreman` to start Rails (via [Puma](http://puma.io/)) and LDAP:

```
foreman start
```

Visit [http://localhost:5000](http://localhost:5000) in your favorite browser.

## Configuration

The first time you access the application you will be greeted with the Setup Wizard.  Please prevent others from accessing the application until you complete the Setup Wizard, as there is no authentication/authorization until the wizard is complete.

The Setup Wizard defaults to the built-in LDAP configuration.  Continue with the test configuration, or update the settings to use your Active Directory server.

### Development user accounts

When using the built-in LDAP configuration, the following accounts exist (username / password):

- hsimpson / 123456
- msimpson / 123456
- bsimpson / 123456
- lsimpson / 123456

### Connecting to GitHub

Visit the Settings page ([/settings](http://localhost:5000/settings)) to configure your connection with GitHub.com.

TODO - More information on configuring GitHub.

## Synchronization

GitHub Connector syncs information from Active Directory and the [GitHub API](https://developer.github.com/v3/) to the local database.  Synchronization is triggered with:

```
rake sync
```

## Rules

GitHub Connector disables organization access based on rules.  Rules are configured via the Settings page.  New rules can be added by extending the `Rules::Base` class in the `lib/rules` directory.

## Tests

Run tests with:

```
rspec
```

Coverage reports are generated in the `coverage` directory.

## Documentation

Generate documentation with:

```
yard
```

Open `doc/index.html` with your favorite browser.

## Customizing

GitHub Connector supports customization via [rails engines](http://guides.rubyonrails.org/engines.html).  If you need to make modifications specific to your organization that don't make sense in an open source repo, use a rails engine.

Creating a new engine is easy:

```
rails plugin new vendor/engines/github_connector_custom_ext --full
```

All engines in the `vendor/engine` directory will be automatically loaded.  An engine's javascript and CSS will be included in `application.js` and `application.css`.

## Contributing

Pull requests welcome!

## Copyright and License

Copyright 2014 Rapid7, Inc.

Released under the [MIT License](http://www.opensource.org/licenses/MIT).
