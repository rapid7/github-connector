class RepositoriesController < ApplicationController
  include SettingsConcern

  before_filter :require_power_user
  before_filter :load_webhooks

  def index
    @organizations = orgs.sort
  end

  def create
    repo_name = create_params.delete(:name)
    repo_slug = "#{create_params[:organization]}/#{repo_name}"
    github_admin_instance.create_repository(repo_name, create_params.except(:name))

    # TODO: Abstract this out of the RepositoriesController#create method
    webhook_params.each_key do |hook_name|
      hook = @webhooks[hook_name]
      if hook['config'].key?('url_template')
        hook['config']['url'] = format(
          hook['config'].delete('url_template'),
          repository_name: repo_name
        )
      end

      github_admin_instance.create_hook(repo_slug, hook_name, hook['config'], hook.except('config'))
    end

    flash[:notice] = "Successfully created #{repo_name} with the webhooks #{webhook_params.keys.join(',')}."
  rescue Octokit::Error => e
    webhooks ||= {}
    flash[:alert] = "Failed to create #{repo_name} with the webhooks #{webhook_params.keys.join(',')}."
  end

  private

  def create_params
    params.require(:repository)
      .permit(:organization, :name, :private, :description, :commit, :events)
      .except(:commit, :events)
  end

  def webhook_params
    params.require(:repository)
      .require(:events)
  end

  def load_webhooks
    @webhooks = Webhook.all
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
