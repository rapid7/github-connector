class RepositoriesController < ApplicationController
  include SettingsConcern

  before_filter :require_power_user

  def index
    @organizations = orgs.sort
  end

  def create
    name = create_params.delete(:name)
    github_admin_instance.create_repository(name, create_params.except(:name))

    flash[:notice] = "Successfully created #{name}.\n#{JSON.pretty_generate(create_params)}"
  rescue Octokit::Error => e
    flash[:alert] = "Failed to create #{name}.\n#{e}"
  end

  private

  def create_params
    params.require(:repository).permit(:organization, :name, :private, :description, :commit).except(:commit)
  end

  def orgs
    settings[:github_orgs].flatten
  end

  def github_admin_instance
    @github_admin ||= GithubAdmin.new
  end

  def settings_keys
    %i[github_orgs]
  end
end
