require 'rails_helper'

RSpec.describe "InventoryItems API", type: :request do
  include ActiveJob::TestHelper
  let!(:inventory_items) { create_list(:inventory_item, 5) }
  let(:inventory_item_id) { inventory_items.first.id }

  describe "GET /inventory_items" do
    it "returns all inventory items" do
      get "/inventory_items"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(5)
    end
  end

  describe "GET /inventory_items/:id" do
    context "when the inventory item exists" do
      it "returns the inventory item" do
        get "/inventory_items/#{inventory_item_id}"

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['id']).to eq(inventory_item_id)
      end
    end

    context "when the inventory item does not exist" do
      it "returns not found" do
        get "/inventory_items/999999"

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq("Inventory item not found")
      end
    end
  end

  describe "POST /inventory_items" do
    let(:valid_attributes) { { inventory_item: { name: "Salt", quantity: 20, low_stock_threshold: 5 } } }
    let(:low_stock_attributes) do
      { inventory_item: { name: "Pepper", quantity: 4, low_stock_threshold: 5 } } # quantity <= threshold
    end

    context "when request is valid" do
      before do
        allow(Inventory::InventoryCheckWorker).to receive(:perform_async)
      end

      it "creates an inventory item" do
        expect {
          post "/inventory_items", params: valid_attributes
        }.to change(InventoryItem, :count).by(1)
  
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['name']).to eq("Salt")
      end

      it "enqueues the inventory check job" do
        post "/inventory_items", params: valid_attributes
        inventory_item = InventoryItem.last
        expect(Inventory::InventoryCheckWorker).to have_received(:perform_async).with(inventory_item.id)
      end

      it "enqueues the inventory check job for low threshold value" do
        post "/inventory_items", params: low_stock_attributes
        inventory_item = InventoryItem.last
        expect(Inventory::InventoryCheckWorker).to have_received(:perform_async).with(inventory_item.id)
      end
    end

    context "when request is invalid" do
      it "returns validation errors" do
        post "/inventory_items", params: { inventory_item: { name: "", quantity: nil } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include("Name can't be blank")
      end
    end
  end

  describe "PUT /inventory_items/:id" do
    let!(:inventory_item) { InventoryItem.create!(name: "Rice", quantity: 20, low_stock_threshold: 10) }
    let(:inventory_item_id) { inventory_item.id }

    let(:valid_update) { { inventory_item: { quantity: 55 } } }

    context "when the inventory item exists" do
      it "updates the item" do
        put "/inventory_items/#{inventory_item_id}", params: valid_update

        expect(response).to have_http_status(:accepted)
        expect(JSON.parse(response.body)['quantity']).to eq(55)
      end

    end

    context "when the inventory item does not exist" do
      it "returns not found" do
        put "/inventory_items/999999", params: valid_update

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq("Inventory item not found")
      end
    end
  end

  describe "DELETE /inventory_items/:id" do
    it "deletes the inventory item" do
      expect {
        delete "/inventory_items/#{inventory_item_id}"
      }.to change(InventoryItem, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns not found when item doesn't exist" do
      delete "/inventory_items/999999"

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)['error']).to eq("Inventory item not found")
    end
  end

  describe "Error handling middleware" do
    it "returns 500 for unexpected errors without backtrace" do
      allow(InventoryItem).to receive(:all).and_raise(StandardError.new("Something went wrong"))

      get "/inventory_items"

      expect(response).to have_http_status(:internal_server_error)
      expect(JSON.parse(response.body)).to eq({ "error" => "Internal Server Error" })
    end
  end
end