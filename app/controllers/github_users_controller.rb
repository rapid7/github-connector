class GithubUsersController < ApplicationController
  before_filter :load_github_user, except: [:index]
  before_filter :require_admin

  def index
    # TODO: Pagination
    @github_users = GithubUser.includes(:user).order(:login)
  end

  def show
  end

  private

  def load_github_user
    @github_user = GithubUser.friendly.find(params[:id])
  end

end
