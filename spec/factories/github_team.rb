FactoryGirl.define do
  factory :github_team do
    sequence(:slug) { |n| "githubteam#{n}" }
  end
end
