FactoryBot.define do
  factory :user do
    company

    sequence(:first_name) { |n| "#{Faker::Name.first_name}#{n}" }
    sequence(:last_name) { |n| "#{Faker::Name.last_name}#{n}" }
    sequence(:email) { |n| "#{n}@example.com" }
    
    test_attribute { Faker::Games::Pokemon.name }
    scoped_attribute { true }
    alternate_email { Faker::Internet.email }
  end
end
