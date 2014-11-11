module Rules
  ##
  # Tests that all GitHub email addresses match the
  # {GithubConnector::Settings#rule_email_regex} setting.  If
  # no `rule_email_regex` setting exists, this rule always
  # returns `true`.
  class Email < Base

    # Returns true if this rule is enabled.
    #
    # @return [Boolean]
    def self.enabled?
      !!settings.rule_email_regex
    end

    # A descriptive error message to display when this rule
    # fails.
    #
    # @return [String]
    def error_msg
      return nil if result

      bad_emails = email_addresses.reject { |email| regex.match(email) }

      "#{bad_emails.count == 1 ? 'Email does' : 'Emails do'} not meet criteria: #{bad_emails.join(', ')}"
    end

    # This rule is required for external users.
    #
    # @return [Boolean] false
    def required_for_external?
      false
    end

    # The result of applying this rule to the {GithubUser}.
    # @return [Boolean] `true` if the rule passes, false otherwise
    def result
      email_addresses.all? { |email| regex.match(email) }
    end

    private

    def email_addresses
      github_user.emails.map { |email| email.address.downcase }
    end

    def regex
      @regex ||= Regexp.new(settings.rule_email_regex)
    end
  end
end
