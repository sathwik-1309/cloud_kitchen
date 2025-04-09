# How to Test

This guide provides a brief overview of how to test the API server, the logical flow of entities, and a few complex scenarios to ensure system correctness and robustness.

## Basic Testing Approach

1. **Refer to API Documentation**  
   All the API routes, expected input payloads, and response formats are detailed in the API Docs. Use this as your primary reference while testing.

2. **Entity Creation Sequence**  
   Before you can place any order, ensure the following prerequisites:
   - **Create a Customer**: Required to get a valid `customer_id`.
   - **Create an Inventory Item**: Required to get valid `inventory_item_id`s.
   - Only after these two steps can you **create an order**.

---

## Recommended Testing Scenarios

### 1. Basic Order Placement
- Create a customer.
- Create one or more inventory items.
- Create an order with one or more items.
- Ensure that the inventory count is reduced accordingly.
- Check that an email is sent to the customer (if email delivery is set up).

---

### 2. Atomic Rollback on Inventory Failure
- Create multiple inventory items.
- Create an order with **multiple items**, where the **last item has insufficient stock**.
- **Expected Behavior**:
  - The order **should not be placed**.
  - Inventory count of **all items should remain unchanged**.
  - This confirms rollback is working as intended within the transaction block.

---

### 3. Inventory Alert Trigger (Low Stock Threshold)
- Create an inventory item with quantity **just above** the low stock threshold.
- Place an order such that the item’s quantity falls **equal to or below the threshold**.
- **Expected Behavior**:
  - An **admin alert email** should be triggered notifying that stock has fallen below the threshold.

---

### 4. No Repeated Alerts When Stock Remains Low
- After the alert is triggered once (above step), create more orders using the same item.
- Even if the stock continues to stay below the threshold, **no additional admin alerts** should be sent.
- This ensures that the `alert_sent` flag is working properly.

---

### 5. Alert Resets When Stock is Replenished
- Update the inventory item so that its quantity goes **above the threshold**.
- This should reset the internal flag (`alert_sent = false`).
- Now place another order that brings the inventory **below the threshold again**.
- **Expected Behavior**:
  - A **new admin alert email** is sent again.

This ensures the system does not spam alerts unnecessarily, and only sends them intelligently when the stock crosses below the threshold **after** a proper reset.

---

## Tools and Setup

- Use **Postman** or any HTTP client to send API requests.
- All API details including endpoints and payload formats can be found in the `api-docs`.
- Ensure your local or containerized environment has the correct `ADMIN_EMAIL` configured in:
  - `.env` (for local runs)
  - `docker-compose.yml` (under both `web` and `sidekiq` services)

---

## Summary

This testing flow ensures:
- Entity creation logic is respected.
- Inventory checks and rollback mechanisms are working.
- Background jobs like email notifications and logging are functioning as expected.
- The admin is not spammed with repeated alerts for the same low-stock condition.