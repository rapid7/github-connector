module GithubConnector
  class Navbar
    include Rails.application.routes.url_helpers

    def sections
      {
        connect: {
          title: 'Add Account',
          url: connect_path,
        },
      }
    end

    def admin_sections
      {
        users: {
          title: 'Users',
          url: users_path,
        },
        github_users: {
          title: 'GitHub Users',
          url: github_users_path,
        },
      }
    end
  end
end
