module Rules
  ##
  # Tests that a {GithubUser} has synced with GitHub
  # within a certain amount of time specified by the
  # {GithubConnector::Settings#rule_max_sync_age} setting.  If no
  # `rule_max_sync_age` setting exists, this rule always returns `true`.
  class LastGithubSync < Base

    # Returns true if this rule is enabled.
    #
    # @return [Boolean]
    def self.enabled?
      !!settings.rule_max_sync_age
    end

    # A descriptive error message to display when this rule
    # fails.
    #
    # @return [String]
    def error_msg
      return nil if result

      if !github_user.last_sync_at
        "GitHub has never been synchronized"
      else
        "Last GitHub synchronization is too old"
      end
    end

    # The result of applying this rule to the {GithubUser}.
    # @return [Boolean] `true` if the rule passes, false otherwise
    def result
      return false unless github_user.last_sync_at

      min_sync_time = Time.now - settings.rule_max_sync_age
      return false unless github_user.last_sync_at > min_sync_time

      true
    end
  end
end
