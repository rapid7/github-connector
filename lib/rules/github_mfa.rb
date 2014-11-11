module Rules
  ##
  # Tests that the {GithubUser} has GitHub multi-factor authentication
  # enabled.
  class GithubMfa < Base

    # A descriptive error message to display when this rule
    # fails.
    #
    # @return [String]
    def error_msg
      return nil if result

      "Two factor authentication is disabled"
    end

    # The result of applying this rule to the {GithubUser}.
    # @return [Boolean] `true` if the rule passes, false otherwise
    def result
      !!github_user.mfa
    end
  end
end
