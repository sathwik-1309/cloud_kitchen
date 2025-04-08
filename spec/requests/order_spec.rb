require 'rails_helper'

RSpec.describe "Orders API", type: :request do
  describe "POST /orders" do
    let(:customer) { create(:customer) }
    let(:inventory_item) { create(:inventory_item, quantity: 10) }

    let(:valid_payload) do
      {
        
        order: {
          customer_id: customer.id,
          items: [
            { inventory_item_id: inventory_item.id, quantity: 3 }
          ]
        }
      }
    end

    context "when the request is valid" do
      it "creates the order successfully" do
        post "/orders", params: valid_payload
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["order"]["id"]).to be_present
        expect(json["order"]["customer_id"]).to eq(customer.id)
        expect(json["order"]["items"].size).to eq(1)
      end

      it "deducts inventory quantity correctly" do
        expect {
          post "/orders", params: valid_payload
        }.to change { inventory_item.reload.quantity }.by(-3)
      end
    end

    context "when inventory is insufficient" do
      it "fails the request and returns an error" do
        inventory_item.update(quantity: 2)

        post "/orders", params: valid_payload

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
        expect(inventory_item.reload.quantity).to eq(2)
      end
    end

    context "when inventory_item_id does not exist" do
      it "returns an error" do
        invalid_payload = valid_payload.deep_dup
        invalid_payload[:order][:items][0][:inventory_item_id] = 99999

        post "/orders", params: invalid_payload

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to be_present
      end
    end

    context "when quantity is 0 or negative" do
      it "returns an error for 0 quantity" do
        invalid_payload = valid_payload.deep_dup
        invalid_payload[:order][:items][0][:quantity] = 0

        post "/orders", params: invalid_payload
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns an error for negative quantity" do
        invalid_payload = valid_payload.deep_dup
        invalid_payload[:order][:items][0][:quantity] = -5

        post "/orders", params: invalid_payload
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when multiple items are passed" do
      let(:item2) { create(:inventory_item, quantity: 5) }

      it "creates the order if all items are valid" do
        multi_payload = {
          order: {
            customer_id: customer.id,
            items: [
              { inventory_item_id: inventory_item.id, quantity: 2 },
              { inventory_item_id: item2.id, quantity: 3 }
            ]
          }
        }

        post "/orders", params: multi_payload

        expect(response).to have_http_status(:created)
        expect(Order.count).to eq(1)
        expect(OrderItem.count).to eq(2)
      end

      it "fails the order if even one item is invalid (e.g., low quantity)" do
        item2.update(quantity: 1)

        multi_payload = {
          order: {
            customer_id: customer.id,
            items: [
              { inventory_item_id: inventory_item.id, quantity: 2 },
              { inventory_item_id: item2.id, quantity: 3 }
            ]
          }
        }

        post "/orders", params: multi_payload

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Order.count).to eq(0)
        expect(OrderItem.count).to eq(0)
      end
    end

    context "when customer_id is missing" do
      it "returns a bad request error" do
        invalid_payload = valid_payload.merge(order: { customer_id: nil })

        post "/orders", params: invalid_payload

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("customer_id and items are required")
      end
    end

    context "when items list is missing or empty" do
      it "returns an error when items are missing" do
        payload = {
          order: {
            customer_id: customer.id,
          }
        }

        post "/orders", params: payload
        expect(response).to have_http_status(:bad_request)
      end

      it "returns an error when items are an empty array" do
        payload = {
          order: { customer_id: customer.id, items: [] }
        }

        post "/orders", params: payload
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when items param is not an array" do
      it "returns an error" do
        payload = {
          customer_id: customer.id,
          order: { items: "not-an-array" }
        }

        post "/orders", params: payload
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when item attributes are malformed or missing keys" do
      it "returns an error for missing inventory_item_id" do
        payload = {
          order: {
            customer_id: customer.id,
            items: [{ quantity: 2 }]
          }
        }

        post "/orders", params: payload
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns an error for missing quantity" do
        payload = {
          order: {
            customer_id: customer.id,
            items: [{ inventory_item_id: inventory_item.id }]
          }
        }

        post "/orders", params: payload
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when the order creation fails because of last item" do
      describe '.create_order' do
        let!(:inventory_item1) { InventoryItem.create!(name: 'Item 1', quantity: 10) }
        let!(:inventory_item2) { InventoryItem.create!(name: 'Item 2', quantity: 5) }
        let!(:inventory_item3) { InventoryItem.create!(name: 'Item 3', quantity: 2) }
    
        it 'rolls back everything if last item has insufficient inventory' do
          items = [
            { inventory_item_id: inventory_item1.id, quantity: 2 },
            { inventory_item_id: inventory_item2.id, quantity: 1 },
            { inventory_item_id: inventory_item3.id, quantity: 5 } # more than available
          ]
    
          payload = {
            order: {
              customer_id: customer.id,
              items: items
            }
          }
  
          post "/orders", params: payload
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          # Check no order was created
          expect(Order.count).to eq(0)
    
          # Check no order items were created
          expect(OrderItem.count).to eq(0)
    
          # Check inventory quantities are unchanged
          expect(inventory_item1.reload.quantity).to eq(10)
          expect(inventory_item2.reload.quantity).to eq(5)
          expect(inventory_item3.reload.quantity).to eq(2)
        end
      end
    end
  end

  describe 'GET #index' do
    let(:customer) { create(:customer) }

    context 'when customer_id is missing' do
      it 'returns 400 bad request' do
        get "/orders"
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Customer ID is required')
      end
    end

    context 'when customer_id is provided' do
      let!(:order1) { Order.create!(customer_id: customer.id, status: Order::Status::PLACED) }
      let!(:order2) { Order.create!(customer_id: customer.id, status: Order::Status::PLACED) }

      it 'returns list of orders for the customer' do
        get "/orders", params: { customer_id: customer.id }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body.length).to eq(2)
        expect(body.map { |o| o["id"] }).to include(order1.id, order2.id)
      end

      it 'respects offset and limit' do
        get "/orders", params: { customer_id: customer.id, offset: 1, limit: 1 }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body.length).to eq(1)
      end
    end
  end

  describe 'GET #show' do
    let(:customer) { create(:customer) }
    let!(:order) { Order.create!(customer_id: customer.id, status: Order::Status::PLACED) }

    context 'when order exists' do
      it 'returns the order with 200 OK' do
        get "/orders/#{order.id}"
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['id']).to eq(order.id)
      end
    end

    context 'when order does not exist' do
      it 'returns 404 not found' do
        get "/orders/99999"
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Order not found')
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:customer) { create(:customer) }
    let!(:order) { Order.create!(customer_id: customer.id, status: Order::Status::PLACED) }

    context 'when cancel succeeds' do
      before do
        allow(OrderService).to receive(:cancel_order).with(order.id.to_s).and_return(true)
      end

      it 'returns 200 OK with success message' do
        delete "/orders/#{order.id}"
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('Order cancelled successfully')
      end
    end

    context 'when cancel fails' do
      before do
        allow(OrderService).to receive(:cancel_order).with(order.id.to_s).and_return(false)
      end

      it 'returns 422 Unprocessable Entity with error message' do
        delete "/orders/#{order.id}"
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Unable to cancel order')
      end
    end
  end
end