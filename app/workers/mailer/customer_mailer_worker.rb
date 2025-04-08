class Mailer::CustomerMailerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform(order_id, customer_id, status)
    order = Order.find_by_id(order_id)
    customer = Customer.find_by_id(customer_id)
    OrderStatusMailer.status_update_mail(order, customer, status).deliver_now if order and customer
  end
end