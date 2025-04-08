FactoryBot.define do
  factory :order_item do
    order
    inventory_item
    quantity { 2 }
  end
end