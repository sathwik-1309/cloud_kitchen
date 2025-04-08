class OrderStatusLog < ApplicationRecord
  belongs_to :order
  validates :status, presence: true, inclusion: { in: Order::Status::ALL }
  validates :changed_at, presence: true

end