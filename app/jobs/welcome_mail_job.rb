class WelcomeMailJob < ApplicationJob
  queue_as :default

  def perform(customer)
    return if customer.nil? || customer.email.nil?

    WelcomeMailer.welcome_email(customer).deliver_now
  rescue StandardError => e
    Rails.logger.error("Failed to send welcome email: #{e.message}")
  end
end