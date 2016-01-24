require 'settings/base'

module GithubConnector
  class Settings < ::Settings::Base
    # @!attribute configured
    #   @return [Boolean] has the application been fully configured?
    setting :configured, type: :boolean

    # @!attribute company
    #   @return [String] Company name
    setting :company, type: :string

    # @!attribute ldap_host
    #   @return [String] Active Directory hostname
    setting :ldap_host

    # @!attribute ldap_port
    #   @return [Integer] Active Directory port
    setting :ldap_port, type: :integer

    # @!attribute ldap_ssl
    #   @return [Boolean] use SSL for Active Directory connection?
    setting :ldap_ssl, type: :boolean

    # @!attribute ldap_admin_user
    #   @return [String] the Active Directory user to use for the LDAP
    #     connection in LDAP format (e.g. cn=admin,dc=example,dc=com)
    setting :ldap_admin_user

    # @!attribute ldap_admin_password
    #   @return [String] the password to use for the LDAP connection
    setting :ldap_admin_password, encrypt: true

    # @!attribute ldap_attribute
    #   @return [String] the LDAP attribute used for the username,
    #     e.g. sAMAccountName
    setting :ldap_attribute

    # @!attribute ldap_base
    #   @return [String] the LDAP base, e.g. dc=example,dc=com
    setting :ldap_base

    # @!attribute github_client_id
    #   @return [String] the GitHub application client ID
    setting :github_client_id

    # @!attribute github_client_secret
    #   @return [String] the GitHub application client secret
    setting :github_client_secret

    # @!attribute github_admin_user
    #   @return [String] the GitHub Oauth token to use for admin/organization
    #     access
    setting :github_admin_token, encrypt: true

    # @!attribute github_orgs
    #   @return [Array] list of GitHub organizations to manage
    setting :github_orgs, type: :array

    # @!attribute github_default_teams
    #   @return [Array] list of GitHub teams all users should belong to
    setting :github_default_teams, type: :array

    # @!attribute github_check_mfa_team
    #   @return [String] the GitHub team used to check 2FA status for new users
    setting :github_check_mfa_team

    # @!attribute github_external_teams
    #   @return [Array] list of teams that allow external users.
    setting :github_external_teams, type: :array

    # @!attribute github_requirements
    #   @return [String] a list of requirements users must meet
    setting :github_user_requirements, type: :array

    # @!attribute github_exclude_users
    #   @return [Array] list of GitHub users to exclude from rules processing
    setting :github_exclude_users, type: :array

    # @!attribute email_base_url
    #   @return [String] the base url to use for links in emails
    setting :email_base_url

    # @!attribute email_from
    #   @return [String] the from address to send emails with
    setting :email_from

    # @!attribute email_reply_to
    #   @return [String] the reply-to address to send emails with
    setting :email_reply_to

    # @!attribute smtp_address
    #   @return [String] remote mail server
    setting :smtp_address

    # @!attribute smtp_port
    #   @return [Fixnum] remote mail server port
    setting :smtp_port

    # @!attribute smtp_enable_starttls_auto
    #   @return [Boolean] allow StartTLS
    setting :smtp_enable_starttls_auto, type: :boolean

    # @!attribute smtp_user_name
    #   @return [String] smtp user name
    setting :smtp_user_name

    # @!attribute smtp_password
    #   @return [String] smtp password
    setting :smtp_password, encrypt: true

    # @!attribute smtp_authentication
    #   @return [String] mail server authenticaton type, one of :plain, :login, or :cram_md5
    setting :smtp_authentication

    # @!attribute smtp_domain
    #   @return [String] smtp HELO domain
    setting :smtp_domain

    # @!attribute enforce_rules
    #   @return [Boolean] true if rules should be enforced, false to for "dry-run"
    #     mode.
    setting :enforce_rules, type: :boolean

    # @!attribute rule_email_regex
    #   @return [String] a regular expression used to validate
    #     GitHub email addresses
    setting :rule_email_regex

    # @!attribute rule_max_sync_age
    #   @return [Fixnum] maximum number of seconds since last sucessful
    #     GitHub synchronization
    setting :rule_max_sync_age, type: :integer

    def github_admin_oauth_scope
      "#{user_oauth_scope},admin:org"
    end

    def github_user_oauth_scope
      'user:email,read:public_key,write:org'
    end

    # Apply Action Mailer related settings to the ActionMailer.
    #
    # @param klass [Class] the ActionMailer class to apply settings to.  Default
    #   ActionMailer::Base.
    # @return [void]
    def apply_to_action_mailer(klass=ActionMailer::Base)
      klass.smtp_settings = smtp_config

      email_opts = email_config
      klass.default_options = email_config.select { |k,v| %i(from reply_to).include?(k) }

      uri = URI.parse(email_opts[:base_url]) rescue nil
      if uri
        host_with_port = uri.host
        host_with_port += ":#{uri.port}" unless uri.port == uri.default_port
        klass.default_url_options = {
          host: host_with_port,
          protocol: uri.scheme,
        }
      end
    end

    # A list of Email configuration keys
    #
    # @return [Array<Symbol>]
    def email_keys
      keys.select { |key| key.to_s.start_with?('email_') }
    end

    # An Email configuration hash.
    #
    # @rturn [Hash]
    def email_config
      hash_for(email_keys).inject({}) do |memo, (key, val)|
        memo[key.to_s.gsub(/^email_/, '').to_sym] = val unless val.is_a?(String) && val.blank?
        memo
      end
    end

    # A list of LDAP configuration keys
    #
    # @return [Array<Symbol>]
    def ldap_keys
      keys.select { |key| key.to_s.start_with?('ldap_') }
    end

    # A LDAP configuration hash that can be consumed by the
    # devise_ldap_authenticatable gem
    #
    # @return [Hash]
    def ldap_config
      hash_for(ldap_keys).inject({}) do |memo, (key, val)|
        memo[key.to_s.gsub(/^ldap_/, '')] = val if key.to_s.start_with?('ldap_')
        memo
      end
    end

    # A list of SMTP configuration keys
    #
    # @return [Array<Symbol>]
    def smtp_keys
      keys.select { |key| key.to_s.start_with?('smtp_') }
    end

    # An SMTP configuration hash that can be consumed by
    # ActionMailer's smtp_settings method.
    #
    # @rturn [Hash]
    def smtp_config
      hash_for(smtp_keys).inject({}) do |memo, (key, val)|
        memo[key.to_s.gsub(/^smtp_/, '').to_sym] = val unless val.is_a?(String) && val.blank?
        memo
      end
    end
  end
end
