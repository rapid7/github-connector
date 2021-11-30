class Setup::AdminUserController < Devise::SessionsController
  include SetupMixin
  prepend_before_action :sign_out_if_signed_in, only: [:new]

  def create
    super do |resource|
      resource.admin = true
      resource.save!
      flash.notice = ''
    end
  end

  protected

  def after_sign_in_path_for(resource)
    setup_github_path
  end

  def sign_out_if_signed_in
    if signed_in?
      Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    end
  end
end
