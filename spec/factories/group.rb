FactoryBot.define do
  factory :group do
    company

    sequence(:name) { |i| "Test Group ##{i}" }

    trait :with_users do
      users { create_list(:user) }
    end
  end
end
