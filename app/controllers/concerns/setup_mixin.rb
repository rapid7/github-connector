module SetupMixin
  extend ActiveSupport::Concern

  included do
    skip_before_filter :authenticate_user!
    before_filter :check_configured
  end

  private
  def apply_defaults
    default_settings.each do |key, val|
      @settings.send("#{key}=", val) unless @settings.send("#{key}")
    end
  end

  def check_configured
    if Rails.application.settings.configured?
      redirect_to settings_url
    end
  end

  # Attempts to figure out the domain name based on the
  # URL or company name
  #
  # @return [String]
  def default_domain
    if request.host == 'localhost' && !Rails.application.settings.company.blank?
      "#{Rails.application.settings.company.downcase.gsub(' ', '_')}.com"
    else
      request.host
    end
  end
end
