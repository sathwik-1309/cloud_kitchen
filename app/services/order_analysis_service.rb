class OrderAnalysisService
  
  def self.update_status(order, status, created_at)
    OrderStatusLog.create!(order: order, status: status, created_at: created_at)
  end

end