class Mailer::WelcomeMailerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform(customer_id)
    customer = Customer.find_by_id(customer_id)
    WelcomeMailer.welcome_email(customer).deliver_now if customer
  end
end