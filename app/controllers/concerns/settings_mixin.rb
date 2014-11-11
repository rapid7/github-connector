module SettingsMixin
  extend ActiveSupport::Concern

  PASSWORD_PLACEHOLDER = '|||PWPLACEHOLDER|||'

  included do
    before_filter :load_settings
  end

  def scrub_password(key)
    if @settings.dirty?(key)
      @settings.send(key)
    else
      PASSWORD_PLACEHOLDER
    end
  end

  private
  def keys
    Rails.application.settings.keys
  end

  def load_settings
    @settings = Rails.application.settings.load(keys).disconnect
    params = self.params[:settings] || {}
    keys.each do |key|
      if params.has_key?(key)
        next if params[key] == PASSWORD_PLACEHOLDER
        if @settings.definition(key).type == :array
          params[key] = params[key].split(/\r?\n/).map(&:strip).compact
        end
        @settings.send("#{key}=", params[key])
      end
    end
  end

  def test_ldap_connection
    ldap = Net::LDAP.new
    ldap.host = @settings.ldap_host
    ldap.port = @settings.ldap_port
    ldap.encryption :simple_tls if @settings.ldap_ssl
    ldap.auth @settings.ldap_admin_user, @settings.ldap_admin_password
    begin
      ldap.bind.tap do |result|
        @error = "Invalid admin user or password." unless result
      end
    rescue => e
      @error = e.message
      Rails.logger.warn "Cannot LDAP bind: #{e.class} - #{e.message}"
      false
    end
  end
end
