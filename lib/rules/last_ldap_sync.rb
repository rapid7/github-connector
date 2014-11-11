module Rules
  ##
  # Tests that a {GithubUser} has synced with Active Directory
  # within a certain amount of time specified by the
  # {GithubConnector::Settings#rule_max_sync_age} setting.  If no
  # `rule_max_sync_age` setting exists, this rule always returns `true`.
  class LastLdapSync < Base

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

      if !user
        "No active directory user"
      elsif !user.last_ldap_sync
        "Active Directory has never been synchronized"
      else
        "Last Active Directory synchornization is too old"
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
      return false unless user
      return false unless user.last_ldap_sync

      min_sync_time = Time.now - settings.rule_max_sync_age
      return false unless user.last_ldap_sync > min_sync_time

      true
    end
  end
end
