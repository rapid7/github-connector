class GithubEmail < ActiveRecord::Base
  belongs_to :github_user

  default_scope { order(:created_at) }
end
