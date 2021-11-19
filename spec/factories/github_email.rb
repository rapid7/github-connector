FactoryBot.define do
  factory :github_email do
    sequence(:address) { |n| "githubemail#{n}@example.com" }
    github_user
  end
end
