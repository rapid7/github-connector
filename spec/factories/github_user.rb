FactoryBot.define do
  factory :github_user do
    sequence(:login) { |n| "githubber#{n}" }

    factory :github_user_with_emails do
      transient do
        emails_count { 2 }
      end

      after(:create) do |github_user, evaluator|
        create_list(:github_email, evaluator.emails_count, github_user: github_user)
      end
    end

    factory :github_user_with_user do
      user
    end
  end
end
