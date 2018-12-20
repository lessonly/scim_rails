FactoryBot.define do
  factory :company do
    name { "Test Company" }
    subdomain { "test" }
    api_token { "1" }
  end
end
