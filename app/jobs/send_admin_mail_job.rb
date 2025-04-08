class SendAdminMailJob < ApplicationJob
  queue_as :default

  def perform(inventory_item_id)
    item = InventoryItem.find_by(id: inventory_item_id)
    return if item.nil?

    AdminMailer.low_inventory_alert(item).deliver_now
  rescue StandardError => e
    Rails.logger.error("Failed to send low inventory alert: #{e.message}")
  end
end