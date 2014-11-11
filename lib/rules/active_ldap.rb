module Rules
  ##
  # Tests that the Active Directory account is active.  The userAccountControl
  # LDAP attribute is used to check for disabled users (disabled flag: 0x0002).
  class ActiveLdap < Base

    # A descriptive error message to display when this rule
    # fails.
    #
    # @return [String]
    def error_msg
      return nil if result

      if user && has_flag?(User::AccountControl::ACCOUNT_DISABLED)
        "Active Directory account is disabled"
      #elsif user && has_flag?(User::AccountControl::PASSWORD_EXPIRED)
      #  "Active Directory password is expired"
      else
        "Active Directory account does not meet criteria"
      end
    end

    # Should this rule notify the user when it is not valid?
    # @return [Boolean]
    def notify?
      false
    end

    # This rule is required for external users.
    #
    # @return [Boolean] false
    def required_for_external?
      false
    end

    # The result of applying this rule to the {User}.
    # @return [Boolean] `true` if the rule passes, false otherwise
    def result
      return false unless user
      return false if has_flag?(User::AccountControl::ACCOUNT_DISABLED)
      #return false if has_flag?(User::AccountControl::PASSWORD_EXPIRED)
      true
    end

    private

    def has_flag?(flag)
      user.ldap_account_control & flag == flag
    end
  end
end
