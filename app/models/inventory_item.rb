class InventoryItem < ApplicationRecord
  validates :name, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :low_stock_threshold, presence: true

end