require 'rails_helper'

RSpec.describe OrderAnalysisService, type: :service do
  let(:customer) { create(:customer) }
  let(:order) { create(:order, customer: customer) }
  let(:status) { "placed" }
  let(:timestamp) { Time.current }

  describe '.update_status' do
    it "creates a new OrderStatusLog with correct details" do
      expect {
        OrderAnalysisService.update_status(order, status, timestamp)
      }.to change(OrderStatusLog, :count).by(1)

      log = OrderStatusLog.last
      expect(log.order).to eq(order)
      expect(log.status).to eq(status)
      expect(log.created_at.to_i).to eq(timestamp.to_i)
    end

    it "raises error if order is nil" do
      expect {
        OrderAnalysisService.update_status(nil, status, timestamp)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "raises error if status is missing" do
      expect {
        OrderAnalysisService.update_status(order, nil, timestamp)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end