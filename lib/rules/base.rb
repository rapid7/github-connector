module Rules
  class Base
    # @return [GithubUser]
    attr_reader :github_user

    # Returns true if this rule is enabled.
    #
    # @return [Boolean]
    def self.enabled?
      true
    end

    def initialize(github_user)
      @github_user = github_user
    end

    # A descriptive error message to display when this rule
    # fails.
    #
    # @return [String]
    def error_msg
      name
    end

    # A name for this rule.
    #
    # @return [String]
    def name
      self.class.name.demodulize.underscore
    end

    # Should this rule notify the user when it is not valid?
    # @return [Boolean]
    def notify?
      true
    end

    # This rule is required for external users.
    #
    # @return [Boolean]
    def required_for_external?
      true
    end

    # The result of applying this rule to the {GithubUser}.
    # @return [Boolean] `true` if the rule passes, false otherwise
    def result
      raise NotImplementedError, "You must implement #{self.class.name}#result"
    end

    # Application settings
    # @return [GithubConnector::Settings]
    def settings
      self.class.settings
    end

    # Application settings
    # @return [GithubConnector::Settings]
    def self.settings
      Rails.application.settings
    end

    # The {User} associated with the {GithubUser}
    # @return [User]
    def user
      github_user.user
    end

    # Returns `true` if the result of the rule is `true`
    # @return [Boolean]
    def valid?
      !!result
    end
  end
end
