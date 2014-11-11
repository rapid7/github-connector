class UserMailer < ActionMailer::Base
  def access_revoked(user, github_user)
    @user = user
    @github_user = github_user
    mail(to: @user.email, subject: 'GitHub Access Revoked')
  end
end
