company = Company.create(
  name: "Test Company",
  subdomain: "test_company",
  api_token: 1
)

1.upto(1000) do |n|
  User.create(
    company: company,
    first_name: "Test#{n}",
    last_name: "User#{n}",
    email: "#{n}@example.com"
  )
end
