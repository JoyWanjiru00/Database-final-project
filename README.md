# E-commerce Store Database Schema

This project provides a **MySQL relational database schema** for a simple e-commerce store. It models users, products, orders, payments, and supporting entities with proper relationships and constraints.

## 📂 Schema Overview

- **Users & Profiles**
  - `users`: Stores account credentials and status.
  - `user_profiles`: One-to-one with `users`, holds personal details.
  - `addresses`: One-to-many from `users`, supports multiple addresses per user.

- **Suppliers & Products**
  - `suppliers`: Companies providing products.
  - `categories`: Organized product groups (self-referencing for subcategories).
  - `products`: Items for sale, linked to suppliers.
  - `product_categories`: Many-to-many between products and categories.
  - `product_images`: Stores multiple images per product.

- **Inventory**
  - `warehouses`: Locations storing products.
  - `inventory`: Stock levels per product per warehouse.

- **Orders & Payments**
  - `orders`: Customer purchases, linked to shipping and billing addresses.
  - `order_items`: Many-to-many between orders and products (with quantity, price).
  - `payments`: Records transactions per order.

- **Reviews**
  - `product_reviews`: User ratings and feedback for products.

- **Views**
  - `vw_product_stock`: Shows total product stock across warehouses.

## 🔑 Constraints & Relationships

- **Primary Keys**: Each table uses `AUTO_INCREMENT` IDs for uniqueness.
- **Foreign Keys**: Ensure referential integrity (e.g., `orders.user_id` → `users.user_id`).
- **One-to-One**: `users` ↔ `user_profiles`.
- **One-to-Many**: `users` → `addresses`, `products` → `product_images`.
- **Many-to-Many**: `products` ↔ `categories` (via `product_categories`), `orders` ↔ `products` (via `order_items`).
- **Checks**: Prevent negative prices, quantities, or totals.
- **Cascade Rules**: 
  - Deleting a `user` cascades to profile and addresses.
  - Deleting a `product` cascades to related images, inventory, and categories.
  - Orders retain history (products restricted from deletion if referenced).

## 📊 Sample Data

The schema includes sample inserts:
- Users (`alice@example.com`, `bob@example.com`, `carol@example.com`)
- Products (Dell Inspiron, HP Pavilion, Denim Jacket, Running Sneakers)
- Categories (Electronics, Laptops, Clothing, Shoes)
- Orders and payments (with example order `ORD-1001`)
- Product reviews (ratings and feedback)

## ▶️ Usage

1. Run the SQL script in MySQL:
   ```sql
   SOURCE ecommerce_schema.sql;
2. Query the database:
   SELECT * FROM users;
    SELECT * FROM vw_product_stock;
    SELECT o.order_number, u.email, o.total_amount
    FROM orders o
    JOIN users u ON o.user_id = u.user_id;

