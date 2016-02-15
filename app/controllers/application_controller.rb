class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :check_configured
  before_action :authenticate_user!
  before_action :load_navbar

  private
  def check_configured
    unless Rails.application.settings.configured?
      redirect_to setup_url
    end
  end

  def require_admin
    return true if current_user.admin?
    render :status => :forbidden, :text => 'Forbidden'
    false
  end

  def load_navbar
    @navbar = GithubConnector::Navbar.new
  end
end
