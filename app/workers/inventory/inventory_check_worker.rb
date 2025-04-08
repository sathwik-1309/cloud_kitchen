class Inventory::InventoryCheckWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform(inventory_item_id)
    inventory_item = InventoryItem.find_by_id(inventory_item_id)
    inventory_item&.check_and_notify_low_stock
  end
end