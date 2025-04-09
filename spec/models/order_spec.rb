require 'rails_helper'

RSpec.describe Order, type: :model do
  describe 'validations' do
    let(:customer) { Customer.create!(name: "Test", email: "test@example.com") }

    it 'is valid with valid attributes' do
      order = Order.new(customer: customer, status: Order::Status::PLACED)
      expect(order).to be_valid
    end

    it 'is invalid without a customer' do
      order = Order.new(status: Order::Status::PLACED)
      expect(order).not_to be_valid
      expect(order.errors[:customer]).to include("can't be blank")
    end

    it 'is invalid without a status' do
      order = Order.new(customer: customer, status: nil)
      expect(order).not_to be_valid
      expect(order.errors[:status]).to include("can't be blank")
    end
  end

  describe '.get_hash' do
    let(:customer) { Customer.create!(name: "Test", email: "test@example.com") }
    let(:order) { Order.create!(customer: customer, status: Order::Status::PLACED) }
    let(:inventory_item) { create(:inventory_item, name: "Test Item", quantity: 10, low_stock_threshold: 5) }
    let!(:item) { create(:order_item, quantity: 2, inventory_item: inventory_item, order: order) }

    it 'returns order with order_items included in json' do
      json_hash = order.get_hash
      expect(json_hash).to include("id" => order.id)
      expect(json_hash["order_items"]).to be_an(Array)
      expect(json_hash["order_items"].first["inventory_item_id"]).to eq(inventory_item.id)
    end

    it 'returns nil if order not found' do
      expect(Order.new(id: -1).get_hash).to be_nil
    end
  end
end