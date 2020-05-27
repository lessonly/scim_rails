FactoryBot.define do
  factory :group do
    company
    users { [] }

    sequence(:display_name) { |n| "#{Faker::Name.name}#{n}" }
    sequence(:email) { |n| "#{Faker::Internet.email}#{n}" }
  end
end
