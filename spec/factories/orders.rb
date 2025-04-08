FactoryBot.define do
  factory :order do
    customer
    status { :placed }
  end
end