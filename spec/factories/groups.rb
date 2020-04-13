FactoryBot.define do
  factory :group do
    company {}
    users { [] }

    display_name { "MyString" }
  end
end
