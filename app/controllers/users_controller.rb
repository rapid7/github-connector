class UsersController < ApplicationController
  before_filter :load_user, except: [:index]
  before_filter :require_admin, except: [:show]
  before_filter :require_admin_or_user, only: [:show]

  def index
    # TODO: Pagination
    @users = User.includes(:github_users).order(:name)
  end

  def show
  end

  def edit
  end

  def update
    @user.update!(user_params)
    redirect_to @user
  end

  private

  def load_user
    @user = User.friendly.find(params[:id])
  end

  def require_admin_or_user
    return true if @user == current_user
    require_admin
  end

  def user_params
    params.require(:user).permit(:admin, :power_user)
  end
end
