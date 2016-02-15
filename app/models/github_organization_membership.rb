class GithubOrganizationMembership < ActiveRecord::Base
  belongs_to :github_user

  default_scope { order(:created_at) }

  def admin?
    role == 'admin'
  end
end
