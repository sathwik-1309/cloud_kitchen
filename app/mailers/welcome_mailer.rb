class WelcomeMailer < ApplicationMailer
  default from: ENV['NOTIFICATION_EMAIL_ID']

  def welcome_email(customer)
    @customer = customer

    mail(
      to: @customer.email,
      from: "Cloud Kitchen",
      subject: "Welcome to Cloud Kitchen! #{customer.name}!"
    )
  end
end