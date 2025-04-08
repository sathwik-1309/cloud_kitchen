class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :inventory_item

  validates :inventory_item_id, :quantity, presence: true
  validates :quantity, numericality: { greater_than: 0 }
end