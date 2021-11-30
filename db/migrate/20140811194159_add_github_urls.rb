class AddGithubUrls < ActiveRecord::Migration[4.2]
  def change
    add_column :github_users, :avatar_url, :string
    add_column :github_users, :html_url, :string
  end
end
