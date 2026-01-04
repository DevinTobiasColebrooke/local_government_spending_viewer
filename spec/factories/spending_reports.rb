FactoryBot.define do
  factory :spending_report do
    sequence(:data_gov_id) { |n| "invoice-#{n}" }
    agency_name { "Department of Example" }
    department_name { "General Services" }
    description { "Office Supplies" }
    amount { "99.99" }
    transaction_date { Date.today }
    category { "Supplies" }
    metadata { {} }
    embedding { nil }
  end
end
