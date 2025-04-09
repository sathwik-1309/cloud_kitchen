# 🍽️ Cloud Kitchen Order Management System

> A robust backend system for managing cloud kitchen operations — handling orders, inventory, and real-time customer/admin notifications using an event-driven, background-job-based architecture.

---

## 📘 Table of Contents

- [Overview](#-overview)
- [Tech Stack](#-tech-stack)
- [Setup Instructions](#-setup-instructions)
- [Running the Project](#-running-the-project)
- [Running Tests](#-running-tests)
- [API Documentation](#-api-documentation)
- [Core Features](#-core-features)
- [System Architecture](#-system-architecture)
- [Models Overview](#-models-overview)
- [ Event-Driven Actions / Background Jobs](#-notifications-via-background-jobs)
- [Contact](#-contact)

---

## 📦 Overview

This Rails project powers the backend of a **Cloud Kitchen platform**. It allows:

- Customers to place and track orders
- Kitchen/admin to manage inventory and get notified on low stock
- Seamless status tracking for every order
- Real-time email notifications to both customers and admins
- All heavy processes to run asynchronously using background workers

---

## 🧰 Tech Stack

| Layer            | Technology                |
|------------------|---------------------------|
| Framework        | Ruby on Rails 7           |
| Database         | PostgreSQL                |
| Background Jobs  | Sidekiq + Redis           |
| Email System     | ActionMailer              |
| API Docs         | Swagger (via RSwag)       |
| Testing          | RSpec, FactoryBot         |

---

## 🛠️ Setup Instructions

### ✅ Option 1 Run in local
### 1. Clone the Repository

```bash
git clone https://github.com/sathwik-1309/cloud_kitchen.git
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Setup ENV variables in .env file

* Use your email id as ADMIN_EMAIL_ID
* Use your redis and postgres Configs
```bash
ADMIN_EMAIL_ID='your_email@gmail.com'

REDIS_URL=redis://localhost:6379/2

DB_HOST='localhost'
POSTGRES_USER='finanza'
POSTGRES_PASSWORD='mypassword'
POSTGRES_DB='cloud_kitchen_dev'

NOTIFICATION_EMAIL_ID='cloudkitchensathwik@gmail.com'
NOTIFICATION_EMAIL_PASSWORD='ztfr pivd trhi sojn'
```

### 4. Setup Database

```bash
rails db:create db:migrate
```

## ️⚡️ Running the Project

### 5. Start Server

```bash
rails s
```

### 6. Start Sidekiq

```bash
bundle exec sidekiq
```

---

### 🚀 OR

### ✅ Option 2: Run with Docker (Recommended for ease)

```bash
docker-compose up --build
```

---

### 🧪 Running Tests

To run the test suite, use:

```bash
bundle exec rspec
```

---

### 📘 API Documentation

A detailed list of all API endpoints, request/response formats, and schema validations is available via Swagger:

🔗 [View API Docs](https://sathwik-1309.github.io/cloud_kitchen/)

---

### 🌟 Core Features

This Cloud Kitchen backend system is designed to simulate real-world operations of a cloud kitchen. It is built using Ruby on Rails and implements event-driven mechanisms, background processing, and smart notifications. Key features include:

- **Order Management**  
  Full CRUD support for managing orders. Each order is associated with a customer and contains one or more order items.

- **Order Items & Inventory**  
  Each `OrderItem` references an `InventoryItem`. Quantity tracking is enforced, and inventory levels update dynamically as orders are placed.

- **Low Stock Alerts**  
  Every `InventoryItem` has a `low_stock_threshold`. When its quantity drops below this value, an automated alert email is sent to the admin via background job processing.

- **Customer Notifications**  
  Customers are notified via email for key events:
  - When an order is created  
  - Whenever an order’s status is updated  

  These emails are triggered asynchronously using Sidekiq jobs.

- **Order Status Logs**  
  Every change in order status is recorded in the `OrderStatusLog` table. This maintains a clear, auditable trail of the order lifecycle.

- **Background Job Processing**  
  All time-consuming tasks like sending emails, status logging and monitoring inventory levels are handled by Sidekiq, ensuring non-blocking performance.

- **Admin Mailer System**  
  A dedicated mailer system alerts administrators about critical events, like low inventory levels, allowing timely action.

This project reflects a simple architecture with a focus on clean structure, performance, and asynchronous communication.

---

### 🧩 Models Overview

This section outlines the core data models and their relationships within the Cloud Kitchen backend.

#### 📦 `Customer`
Represents a customer placing orders.

| Column | Type   | Notes                 |
|--------|--------|-----------------------|
| id    | integer| auto incremented              |
| name   | string | Required              |
| email  | string | Required, Unique      |
| created_at  | datetime | auto maintained     |
| updated_at  | datetime | auto maintained     |

- Has many `orders`

---

#### 📦 `InventoryItem`
Tracks items that can be ordered.

| Column             | Type    | Notes                                          |
|--------------------|---------|------------------------------------------------|
| id    | integer| auto incremented              |
| name               | string  | Required                                       |
| quantity           | integer | Required, defaults to 0                        |
| low_stock_threshold| integer | Required, defaults to 0                        |
| low_stock_alert_sent | boolean | Used to prevent duplicate alerts             |
| created_at  | datetime | auto maintained     |
| updated_at  | datetime | auto maintained     |

- Has many `order_items`
- Triggers admin alert emails when quantity falls below threshold.

---

#### 📦 `Order`
Represents an order placed by a customer.

| Column    | Type    | Notes                                                |
|-----------|---------|------------------------------------------------------|
| id    | integer| auto incremented              |
| customer_id | reference | Required, foreign key to `customers` table     |
| status    | string  | Enum: `placed`, `preparing`, `shipped`, `delivered`, `cancelled` |
| created_at  | datetime | auto maintained     |
| updated_at  | datetime | auto maintained     |

- Belongs to `customer`
- Has many `order_items`
- Has many `order_status_logs`

---

#### 📦 `OrderItem`
Line items in an order, linked to inventory.

| Column         | Type    | Notes                                  |
|----------------|---------|----------------------------------------|
| id    | integer| auto incremented              |
| order_id       | reference | Required, foreign key to `orders`    |
| inventory_item_id | reference | Required, foreign key to `inventory_items` |
| quantity       | integer | Required, defaults to 1               |
| created_at  | datetime | auto maintained     |
| updated_at  | datetime | auto maintained     |

- Belongs to `order`
- Belongs to `inventory_item`

---

#### 📦 `OrderStatusLog`
Tracks the lifecycle of an order via status changes.

| Column    | Type    | Notes                                |
|-----------|---------|--------------------------------------|
| id    | integer| auto incremented              |
| order_id  | reference | Required, foreign key to `orders` |
| status    | string  | Required                            |
| created_at  | datetime | auto maintained     |
| updated_at  | datetime | auto maintained     |

- Belongs to `order`
- Automatically populated when order status is updated

---

🔗 **Indexes & Foreign Keys**
All foreign keys (`references`) include automatic indexing via `foreign_key: true`, ensuring relational integrity and efficient query performance.

---

### ⚙️ Event-Driven Actions / Background Jobs

The application is designed with an event-driven architecture using Sidekiq to handle asynchronous processes efficiently. The following key background jobs are executed based on different triggers:

#### 📩 WelcomeMailerJob
- Triggered when a new customer is created.
- Sends a welcome email to the registered customer.

#### 📬 CustomerMailerJob
- Triggered when an order is created or its status is updated.
- Sends real-time order notifications and updates to the customer's email.

#### 📝 OrderStatusLoggerJob
- Triggered every time an order status changes.
- Logs the status change into the `order_status_logs` table for audit/history tracking.

#### 🚨 AdminMailerJob
- Triggered when the quantity of an `InventoryItem` goes below or equals its `low_stock_threshold`.
- Sends an alert email to the admin to restock the item, ensuring inventory reliability.

These background jobs ensure a responsive user experience and decouple heavy operations from the main request cycle.

---

## 📬 Contact

For any queries, collaborations, or suggestions, feel free to reach out:

- 📧 Email: [sathwik139@gmail.com](mailto:sathwik139@gmail.com)  
- 📞 Phone: +91-9480217131 
- 👤 Name: Sathwik Anil