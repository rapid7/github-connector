GitHub Active Directory Connector Cookbook
==========================================

Installs and configures the GitHub Active Directory Connector via Chef.

This performs the following actions:

1. Creates a `github` user
2. Installs PostgreSQL and creates a database
3. Installs RVM, installs ruby, and configures a `github-connector` gemset
4. Clones the `github-connector` repository from GitHub
5. Creates upstart jobs for the web and worker processes
6. Creates a cron job to synchronize users
