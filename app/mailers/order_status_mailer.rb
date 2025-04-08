class OrderStatusMailer < ApplicationMailer
  default from: ENV['NOTIFICATION_EMAIL_ID']

  def status_update(order, customer)
    @order = order
    @status_message = status_message_for(@order.status)
    @customer = customer

    mail(
      to: customer.email,
      from: "Cloud Kitchen <#{ENV['NOTIFICATION_EMAIL_ID']}>",
      subject: "Your Order ##{@order.id} - #{@order.status.titleize}"
    )
  end

  private

  def status_message_for(status)
    case status.to_sym
    when :placed
      "Your order has been placed."
    when :preparing
      "Your order is being prepared."
    when :out_for_delivery
      "Your order is out for delivery."
    when :delivered
      "Your order has been delivered."
    when :cancelled
      "Your order has been cancelled."
    else
      "Your order status has been updated."
    end
  end
end