class Setup::EmailController < ApplicationController
  include SetupMixin
  include SettingsMixin

  def edit
    apply_defaults unless @settings.smtp_address
  end

  def update
    @settings.save

    redirect_to setup_rules_url
  end

  private

  def default_settings
    {
      email_from: "github@#{default_domain}",
      email_base_url: root_url,
      smtp_address: "smtp.#{default_domain}",
      smtp_port: '25',
      smtp_enable_starttls_auto: true,
    }
  end
end
