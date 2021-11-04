class UsersController < ApplicationController
  before_action :load_user, except: [:index]
  before_action :require_admin, except: [:show]
  before_action :require_admin_or_user, only: [:show]

  def index
    # TODO: Pagination
    @users = User.includes(:github_users).order(:name)
    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @user }
    end
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
    params.require(:user).permit(:admin)
  end
end
