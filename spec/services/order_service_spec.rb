require 'rails_helper'

RSpec.describe OrderService, type: :service do
  let(:customer) { create(:customer) }
  let(:inventory_item) { create(:inventory_item, quantity: 10, low_stock_threshold: 5) }

  describe ".create_order" do
    context "when the request is valid" do
      let(:items) { [{ inventory_item_id: inventory_item.id, quantity: 3 }] }

      before do
        allow(Mailer::CustomerMailerWorker).to receive(:perform_async)
        allow(Logs::UpdateAnalysisWorker).to receive(:perform_async)
        allow(Inventory::InventoryCheckWorker).to receive(:perform_async)
      end

      it "creates an order and deducts inventory" do
        result = OrderService.create_order(customer.id, items)

        expect(result[:success]).to be true
        expect(Order.count).to eq(1)
        expect(OrderItem.count).to eq(1)
        expect(inventory_item.reload.quantity).to eq(7)
        expect(Mailer::CustomerMailerWorker).to have_received(:perform_async).once
        expect(Logs::UpdateAnalysisWorker).to have_received(:perform_async).once
        expect(Inventory::InventoryCheckWorker).to have_received(:perform_async).with(inventory_item.id)
      end
    end

    context "when an item is invalid" do
      it "returns failure and does not create order" do
        result = OrderService.create_order(customer.id, [{ inventory_item_id: 999, quantity: 2 }])
        expect(result[:success]).to be false
        expect(result[:error]).to include("Invalid inventory item ID")
        expect(Order.count).to eq(0)
      end
    end

    context "when inventory is insufficient" do
      it "returns failure and does not create order" do
        result = OrderService.create_order(customer.id, [{ inventory_item_id: inventory_item.id, quantity: 20 }])
        expect(result[:success]).to be false
        expect(result[:error]).to include("out of stock")
        expect(Order.count).to eq(0)
      end
    end
  end

  describe ".list_orders" do
    before do
      create_list(:order, 3, customer: customer)
    end

    it "returns the list of orders" do
      result = OrderService.list_orders(customer.id, 0, 10)
      expect(result.count).to eq(3)
      expect(result.first).to be_a(Order)
    end
  end

  describe ".cancel_order" do
    let!(:order) do
      order = create(:order, customer: customer, status: :placed)
      create(:order_item, order: order, inventory_item: inventory_item, quantity: 2)
      order
    end

    before do
      allow(Mailer::CustomerMailerWorker).to receive(:perform_async)
      allow(Logs::UpdateAnalysisWorker).to receive(:perform_async)
    end

    context "when order is placed" do
      it "cancels the order and restores inventory" do
        expect {
          result = OrderService.cancel_order(order)
          expect(result).to be true
        }.to change { inventory_item.reload.quantity }.by(2)

        expect(order.reload.status).to eq("cancelled")
        expect(Mailer::CustomerMailerWorker).to have_received(:perform_async)
        expect(Logs::UpdateAnalysisWorker).to have_received(:perform_async)
      end
    end

    context "when order is not cancellable" do
      it "returns false" do
        order.update!(status: :delivered)
        expect(OrderService.cancel_order(order)).to be false
      end
    end
  end

  describe ".update_order_status" do
    let!(:order) { create(:order, customer: customer, status: :placed) }

    before do
      allow(Mailer::CustomerMailerWorker).to receive(:perform_async)
      allow(Logs::UpdateAnalysisWorker).to receive(:perform_async)
    end

    context "with valid new status" do
      it "updates the order and enqueues background jobs" do
        updated = OrderService.update_order_status(order, "preparing")
        expect(updated.status).to eq("preparing")
        expect(Mailer::CustomerMailerWorker).to have_received(:perform_async)
        expect(Logs::UpdateAnalysisWorker).to have_received(:perform_async)
      end
    end

    context "with invalid status" do
      it "raises ValidationError" do
        expect {
          OrderService.update_order_status(order, "invalid_status")
        }.to raise_error(ValidationError)
      end
    end
  end
end