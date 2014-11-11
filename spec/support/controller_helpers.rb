module ControllerHelpers
  def sign_in(user=nil)
    user = create(:user) unless user
    super(user)
  end

  def configured
    Rails.application.settings.configured = true
  end
end
