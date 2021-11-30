class AddGithubUserDisabledTeams < ActiveRecord::Migration[4.2]
  def change
    create_table :github_user_disabled_teams, id: false do |t|
      t.belongs_to :github_user
      t.belongs_to :github_team
    end
  end
end
