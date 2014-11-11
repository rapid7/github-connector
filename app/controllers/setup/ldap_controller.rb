class Setup::LdapController < ApplicationController
  include SetupMixin
  include SettingsMixin

  def edit
    apply_defaults unless @settings.ldap_host
  end

  def update
    unless test_ldap_connection
      render :edit
      return
    end
    @settings.save

    redirect_to setup_admin_url
  end


  private

  def default_settings
    {
      ldap_host: 'localhost',
      ldap_port: 3268,
      ldap_ssl: false,
      ldap_admin_user: "cn=admin,#{default_base}",
      ldap_admin_password: 'secret',
      ldap_base: default_base,
      ldap_attribute: 'sAMAccountName',
    }
  end

  def keys
    Rails.application.settings.ldap_keys
  end

  def default_base
    if request.host == 'localhost'
      'dc=example,dc=com'
    else
      default_domain.split('.').map {|s| "dc=#{s}"}.join(',')
    end
  end
end
