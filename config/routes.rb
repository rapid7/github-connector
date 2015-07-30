Rails.application.routes.draw do
  get 'settings', to: 'settings#edit'
  put 'settings', to: 'settings#update'
  get 'settings/github_admin', to: 'settings#github_admin'
  get 'settings/github_auth_code', to: 'settings#github_auth_code'

  get 'setup', to: redirect('setup/company')
  namespace :setup do
    # Step 1
    get 'company', to: 'company#edit'
    put 'company', to: 'company#update'
    # Step 2
    get 'ldap', to: 'ldap#edit'
    put 'ldap', to: 'ldap#update'
    # Step 3
    devise_scope :user do
      get 'admin', to: 'admin_user#new'
      post 'admin', to: 'admin_user#create'
    end
    # Step 4
    get 'github', to: 'github#edit'
    get 'github_auth_code', to: 'github#github_auth_code'
    put 'github', to: 'github#update'
    # Step 5
    get 'email', to: 'email#edit'
    put 'email', to: 'email#update'
    # Step 6
    get 'rules', to: 'rules#edit'
    put 'rules', to: 'rules#update'
  end

  get 'connect', to: 'connect#index'
  get 'connect/start', to: 'connect#start'
  get 'connect/auth_code', to: 'connect#auth_code'
  get 'connect/:id', to: 'connect#status', as: 'connect_status', constraints: { id: /\d+/ }

  devise_for :users

  resources :users, only: [:index, :show, :edit, :update], constraints: { id: /[^\/]+/ }
  resources :github_users, only: [:index, :show]

  root 'dashboard#index'
end
