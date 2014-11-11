module ActionMailer
  class Base

    # Read mailer configuration settings from the database every time
    # we instantiate a new mailer.
    def initialize_with_config(*args)
      Rails.application.settings.apply_to_action_mailer
      initialize_without_config(*args)
    end
    alias_method_chain :initialize, :config

  end
end
