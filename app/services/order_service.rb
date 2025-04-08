class OrderService

  def self.create_order(customer_id, items)
    ActiveRecord::Base.transaction do
      order = Order.create!(customer_id: customer_id, status: Order::Status::PLACED)
      order_items = []
  
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
          raise "Order could not be placed. inventory item #{inventory_item_id} is out of stock."
        end
  
        order_item = OrderItem.create!(
          order_id: order.id,
          inventory_item_id: inventory_item_id,
          quantity: quantity
        )
        order_items << order_item
      end
  
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

  def self.find_order(order_id)
    Order.includes(:order_items).find_by(id: order_id)
  end

  def self.cancel_order(order_id)
    order = Order.find_by(id: order_id)

    return false if order.nil? || order.status != 'placed'

    Order.transaction do
      order.order_items.each do |item|
        InventoryItem.where(id: item.inventory_item_id)
                     .update_all("quantity = quantity + #{item.quantity}")
      end

      order.update!(status: :cancelled)
    end

    true
  rescue
    false
  end

end