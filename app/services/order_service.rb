class OrderService

  def self.create_order(customer_id, items)
    ActiveRecord::Base.transaction do
      order = Order.create!(customer_id: customer_id, status: Order::Status::PLACED)
      order_items = []
      inventory_items_to_check = []
  
      items.each do |item|
        inventory_item_id = item[:inventory_item_id]
        quantity = item[:quantity].to_i
  
        unless InventoryItem.exists?(id: inventory_item_id)
          raise "Invalid inventory item ID: #{inventory_item_id}"
        end
  
        updated_rows = InventoryItem
                         .where(id: inventory_item_id)
                         .where("quantity >= ?", quantity)
                         .update_all("quantity = quantity - #{quantity}")
  
        if updated_rows == 0
          raise "Order could not be placed. Inventory item #{inventory_item_id} is out of stock."
        end
  
        order_item = OrderItem.create!(
          order_id: order.id,
          inventory_item_id: inventory_item_id,
          quantity: quantity
        )
        order_items << order_item
        inventory_items_to_check << inventory_item_id
      end
  
      # After all goes well, enqueue jobs
      inventory_items_to_check.each do |inventory_item_id|
        inventory_item = InventoryItem.find(inventory_item_id)
        Inventory::InventoryCheckWorker.perform_async(inventory_item.id)
      end
      
      Mailer::CustomerMailerWorker.perform_async(order.id, order.customer_id, order.status)
      Logs::UpdateAnalysisWorker.perform_async(order.id, order.status, order.created_at.to_s)
  
      return {
        success: true,
        order: order.as_json.merge(
          items: order_items.map { |item|
            {
              id: item.id,
              inventory_item_id: item.inventory_item_id,
              quantity: item.quantity
            }
          }
        )
      }
    end
  
  rescue => e
    return {
      success: false,
      error: e.message || "Order could not be placed. One or more items may be out of stock."
    }
  end

  def self.list_orders(customer_id, offset, limit)
    Order.includes(:order_items).where(customer_id: customer_id).order(created_at: :desc).offset(offset).limit(limit)
  end

  def self.cancel_order(order)
    return false if order.status != 'placed'

    Order.transaction do
      order.order_items.each do |item|
        InventoryItem.where(id: item.inventory_item_id)
                     .update_all("quantity = quantity + #{item.quantity}")
      end

      order.update!(status: :cancelled)
    end
    Mailer::CustomerMailerWorker.perform_async(order.id, order.customer_id, Order::Status::CANCELLED)
    Logs::UpdateAnalysisWorker.perform_async(order.id, Order::Status::CANCELLED, order.updated_at.to_s)

    true
  rescue
    false
  end

  def self.update_order_status(order, new_status)
    if Order::Status.constants.map(&:to_s).map(&:downcase).include?(new_status)
      order.update(status: new_status)
      Mailer::CustomerMailerWorker.perform_async(order.id, order.customer_id, new_status)
      Logs::UpdateAnalysisWorker.perform_async(order.id, new_status, order.updated_at.to_s)
      order
    else
      raise ValidationError.new(message: "Invalid status: #{new_status}")
    end
  end

end