FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "fakeuser#{n}" }

    factory :user_with_github_users do
      transient do
        github_users_count { 2 }
      end
    end

    factory :admin_user do
      admin { true }
    end
  end
end
