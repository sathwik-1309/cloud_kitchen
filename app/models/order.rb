class Order < ApplicationRecord
  has_many :order_items, dependent: :destroy
  has_many :order_status_logs, dependent: :destroy
  belongs_to :customer

  module Status
    PLACED            = "placed"
    PREPARING         = "preparing"
    OUT_FOR_DELIVERY  = "out_for_delivery"
    DELIVERED         = "delivered"
    CANCELLED         = "cancelled"

    ALL = [
      PLACED,
      PREPARING,
      OUT_FOR_DELIVERY,
      DELIVERED,
      CANCELLED
    ]
  end

  enum status: {
    placed: Status::PLACED,
    preparing: Status::PREPARING,
    out_for_delivery: Status::OUT_FOR_DELIVERY,
    delivered: Status::DELIVERED,
    cancelled: Status::CANCELLED
  }

  validates :customer, presence: true
  validates :status, presence: true, inclusion: { in: Status::ALL }

  def get_hash
    Order.includes(:order_items).find_by(id: self.id)
  end
end