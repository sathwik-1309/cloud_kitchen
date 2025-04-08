class OrderAnalysisService
  
  def update_status(order, created_at)
    OrderStatusLog.create!(order: order, status: order.status, created_at: created_at)
  end

end