FactoryBot.define do
  factory :group do
    company
    users { [] }

    display_name { Faker::Name.name }
  end
end
