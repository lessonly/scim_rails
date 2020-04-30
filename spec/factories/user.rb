FactoryBot.define do
  factory :user do
    company

    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    sequence(:email) { |n| "#{n}@example.com" }
  end
end
