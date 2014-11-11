class AddGithubUserDisabledTeams < ActiveRecord::Migration
  def change
    create_table :github_user_disabled_teams, id: false do |t|
      t.belongs_to :github_user
      t.belongs_to :github_team
    end
  end
end
