class UpdateAnalysisJob < ApplicationJob
  queue_as :default

  def perform(order, status, created_at)
    return if order.nil?

    OrderAnalysisService.update_status(order, status, created_at)
  rescue StandardError => e
    Rails.logger.error("Failed to update order analysis: #{e.message}")
  end
end