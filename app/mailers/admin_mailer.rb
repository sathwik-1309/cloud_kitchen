class AdminMailer < ApplicationMailer
  default from: ENV['NOTIFICATION_EMAIL_ID']

  def low_inventory_alert(inventory_item)
    @item = inventory_item
    mail(
      from: "Cloud Kitchen Inventory",
      to: ENV['ADMIN_EMAIL_ID'],
      subject: "Low Inventory Alert: #{@item.name}"
    )
  end
end
