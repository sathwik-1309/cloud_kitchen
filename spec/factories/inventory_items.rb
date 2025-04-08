FactoryBot.define do
  factory :inventory_item do
    sequence(:name) { |n| "Item#{n}" }
    quantity { 100 }
    low_stock_threshold { 10 }
  end
end