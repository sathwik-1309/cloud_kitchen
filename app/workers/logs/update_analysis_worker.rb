class Logs::UpdateAnalysisWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform(order_id, status, created_at)
    order = Order.find_by_id(order_id)
    OrderAnalysisService.update_status(order, status, created_at) if order
  end
end