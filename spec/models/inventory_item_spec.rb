require 'rails_helper'

RSpec.describe InventoryItem, type: :model do
  describe '#check_and_notify_low_stock' do
    let(:item) { create(:inventory_item, name: "Pepper", quantity: 10, low_stock_threshold: 10, low_stock_alert_sent: false) }

    before do
      allow(AdminMailer).to receive_message_chain(:low_inventory_alert, :deliver_now)
    end

    context 'when quantity is equal to threshold and alert not yet sent' do
      it 'sends low stock alert and updates flag' do
        item.check_and_notify_low_stock

        expect(AdminMailer).to have_received(:low_inventory_alert).with(item)
        expect(item.reload.low_stock_alert_sent).to be true
      end
    end

    context 'when quantity is below threshold and alert already sent' do
      before do
        item.update!(quantity: 9, low_stock_alert_sent: true)
      end

      it 'does not send alert again' do
        item.check_and_notify_low_stock

        expect(AdminMailer).not_to have_received(:low_inventory_alert)
        expect(item.reload.low_stock_alert_sent).to be true
      end
    end

    context 'when quantity rises above threshold after alert was sent' do
      before do
        item.update!(quantity: 11, low_stock_alert_sent: true)
      end

      it 'resets the alert flag' do
        item.check_and_notify_low_stock

        expect(AdminMailer).not_to have_received(:low_inventory_alert)
        expect(item.reload.low_stock_alert_sent).to be false
      end
    end

    context 'when alert was reset and quantity drops again' do
      before do
        item.update!(quantity: 11, low_stock_alert_sent: true)
        item.check_and_notify_low_stock # resets flag
        item.update!(quantity: 9)
      end

      it 'sends alert again on drop and updates flag' do
        item.check_and_notify_low_stock

        expect(AdminMailer).to have_received(:low_inventory_alert).with(item)
        expect(item.reload.low_stock_alert_sent).to be true
      end
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      item = InventoryItem.new(name: 'Salt', quantity: 5, low_stock_threshold: 2)
      expect(item).to be_valid
    end

    it 'is invalid without a name' do
      item = InventoryItem.new(name: nil, quantity: 5, low_stock_threshold: 2)
      expect(item).to be_invalid
      expect(item.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without a low_stock_threshold' do
      item = InventoryItem.new(name: 'Salt', quantity: 5, low_stock_threshold: nil)
      expect(item).to be_invalid
      expect(item.errors[:low_stock_threshold]).to include("can't be blank")
    end

    it 'is invalid if quantity is negative' do
      item = InventoryItem.new(name: 'Salt', quantity: -1, low_stock_threshold: 2)
      expect(item).to be_invalid
      expect(item.errors[:quantity]).to include("must be greater than or equal to 0")
    end

    it 'is invalid if low_stock_threshold is negative' do
      item = InventoryItem.new(name: 'Salt', quantity: 5, low_stock_threshold: -3)
      expect(item).to be_invalid
      expect(item.errors[:low_stock_threshold]).to include("must be greater than or equal to 0")
    end
  end
end