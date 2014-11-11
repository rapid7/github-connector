module Rules
  ##
  # Tests that a {GithubUser} has valid GitHub OAuth access.  This is
  # evaluated by looking at the {GithubUser#sync_error} field for
  # `notoken` or `unauthorized` errors.
  class GithubOauth < Base

    # A descriptive error message to display when this rule
    # fails.
    #
    # @return [String]
    def error_msg
      return nil if result

      if github_user.token
        "Invalid OAuth token"
      else
        "Missing OAuth token"
      end
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
      return false unless github_user.token
      return false if %w(notoken unauthorized).include?(github_user.sync_error)
      true
    end
  end
end
