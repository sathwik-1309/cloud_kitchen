class InventoryItem < ApplicationRecord
  validates :name, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :low_stock_threshold, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def check_and_notify_low_stock
    if quantity <= low_stock_threshold && !low_stock_alert_sent
      AdminMailer.low_inventory_alert(self).deliver_now
      update_column(:low_stock_alert_sent, true)
    elsif quantity > low_stock_threshold && low_stock_alert_sent
      update_column(:low_stock_alert_sent, false)
    end
  end

end