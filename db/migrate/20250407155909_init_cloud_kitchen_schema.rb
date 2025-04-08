class InitCloudKitchenSchema < ActiveRecord::Migration[7.1]
  def change

    create_table :customers do |t|
      t.string :name, null: false
      t.string :email, null: false, index: { unique: true }
      t.timestamps
    end

    create_table :inventory_items do |t|
      t.string :name, null: false
      t.integer :quantity, null: false, default: 0
      t.integer :low_stock_threshold, null: false, default: 0
      t.boolean :low_stock_alert_sent, null: false, default: false
      t.timestamps
    end

    create_table :orders do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :status, null: false, default: "placed"  # Can be placed, preparing, shipped, delivered, cancelled
      t.timestamps
    end

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :inventory_item, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.timestamps
    end

    create_table :order_status_logs do |t|
      t.references :order, null: false, foreign_key: true
      t.string :status, null: false
      t.timestamps
    end
  end
end
