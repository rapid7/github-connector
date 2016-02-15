FactoryGirl.define do
  factory :github_organization_membership do
    sequence(:organization) { |n| "org#{n}" }
    github_user
  end
end
