class SendCustomerMailJob < ApplicationJob
  queue_as :default

  def perform(order, customer)
    return if order.nil? || customer&.email.nil?
    
    OrderStatusMailer.status_update(order, customer).deliver_now
  rescue StandardError => e
    Rails.logger.error("Failed to send order status email: #{e.message}")
  end
end