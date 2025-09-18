-- ecommerce_schema.sql
-- E-commerce Store relational schema for MySQL (InnoDB)
-- Contains: CREATE DATABASE, CREATE TABLEs, constraints, indexes, relationships.

DROP DATABASE IF EXISTS ecommerce_store;
CREATE DATABASE ecommerce_store
  CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

USE ecommerce_store;

-- -----------------------------
-- Users (customers / auth)
-- -----------------------------
CREATE TABLE users (
  user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- -----------------------------
-- User profiles (one-to-one with users)
-- -----------------------------
CREATE TABLE user_profiles (
  user_id BIGINT UNSIGNED PRIMARY KEY,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  phone VARCHAR(30),
  birth_date DATE,
  bio TEXT,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------
-- Addresses (one-to-many: user -> addresses)
-- -----------------------------
CREATE TABLE addresses (
  address_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  label VARCHAR(50), -- e.g., "home", "office"
  street VARCHAR(255) NOT NULL,
  city VARCHAR(100) NOT NULL,
  state VARCHAR(100),
  postal_code VARCHAR(30),
  country VARCHAR(100) NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_addresses_user_id ON addresses(user_id);

-- -----------------------------
-- Suppliers
-- -----------------------------
CREATE TABLE suppliers (
  supplier_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  contact_email VARCHAR(255),
  phone VARCHAR(50),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------
-- Categories
-- -----------------------------
CREATE TABLE categories (
  category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL UNIQUE,
  slug VARCHAR(150) NOT NULL UNIQUE,
  parent_id INT UNSIGNED DEFAULT NULL, -- self-referencing for category trees
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (parent_id) REFERENCES categories(category_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------
-- Products
-- -----------------------------
CREATE TABLE products (
  product_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(100) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(12,2) NOT NULL CHECK (price >= 0),
  weight_kg DECIMAL(8,3) DEFAULT NULL,
  supplier_id BIGINT UNSIGNED,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_products_supplier ON products(supplier_id);


-- -----------------------------
-- Product <-> Category (many-to-many)
-- -----------------------------
CREATE TABLE product_categories (
  product_id BIGINT UNSIGNED NOT NULL,
  category_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (product_id, category_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------
-- Product images (one-to-many)
-- -----------------------------
CREATE TABLE product_images (
  image_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  url VARCHAR(2048) NOT NULL,
  alt_text VARCHAR(255),
  sort_order INT UNSIGNED DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_product_images_product ON product_images(product_id);

-- -----------------------------
-- Inventory (one row per product per location/warehouse)
-- -----------------------------
CREATE TABLE warehouses (
  warehouse_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  location VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE inventory (
  product_id BIGINT UNSIGNED NOT NULL,
  warehouse_id INT UNSIGNED NOT NULL,
  quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (product_id, warehouse_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------
-- Orders
-- -----------------------------
CREATE TABLE orders (
  order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_number VARCHAR(50) NOT NULL UNIQUE,
  user_id BIGINT UNSIGNED NOT NULL,
  shipping_address_id BIGINT UNSIGNED,
  billing_address_id BIGINT UNSIGNED,
  total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
  currency CHAR(3) NOT NULL DEFAULT 'USD',
  status VARCHAR(30) NOT NULL DEFAULT 'pending', -- e.g., pending, paid, shipped, cancelled
  placed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  FOREIGN KEY (billing_address_id) REFERENCES addresses(address_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_orders_user ON orders(user_id);

-- -----------------------------
-- Order items (many-to-many: orders <-> products with quantity, price)
-- -----------------------------
CREATE TABLE order_items (
  order_id BIGINT UNSIGNED NOT NULL,
  order_item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id BIGINT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0),
  line_total DECIMAL(14,2) NOT NULL AS (quantity * unit_price) VIRTUAL,
  PRIMARY KEY (order_id, order_item_id),
  FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_order_items_product ON order_items(product_id);

-- -----------------------------
-- Payments (one-to-one-ish: an order can have multiple payments but often 1)
-- -----------------------------
CREATE TABLE payments (
  payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT UNSIGNED NOT NULL,
  paid_amount DECIMAL(12,2) NOT NULL CHECK (paid_amount >= 0),
  method VARCHAR(50) NOT NULL, -- e.g., card, paypal
  provider_reference VARCHAR(255),
  status VARCHAR(50) NOT NULL DEFAULT 'completed',
  paid_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_payments_order ON payments(order_id);

-- -----------------------------
-- Product reviews (one-to-many: product -> reviews)
-- -----------------------------
CREATE TABLE product_reviews (
  review_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED,
  rating TINYINT UNSIGNED NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title VARCHAR(255),
  body TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_reviews_product ON product_reviews(product_id);

-- -----------------------------
-- Example constraints / integrity helpers
-- -----------------------------
-- Prevent negative total_amount at DB level (redundant w/ CHECK above for supporting versions)
ALTER TABLE orders ADD CONSTRAINT chk_orders_total_amount_nonneg CHECK (total_amount >= 0);

-- -----------------------------
-- Useful views (optional)
-- -----------------------------
-- View: product stock across warehouses
CREATE OR REPLACE VIEW vw_product_stock AS
SELECT p.product_id, p.sku, p.name,
       IFNULL(SUM(i.quantity),0) AS total_quantity
FROM products p
LEFT JOIN inventory i ON p.product_id = i.product_id
GROUP BY p.product_id, p.sku, p.name;

-- -----------------------------
-- Sample user to help testing (comment out in production)
-- -----------------------------
-- INSERT INTO users (email, password_hash) VALUES ('test@example.com', 'hashed_password_here');

-- End of schema
-- -----------------------------
-- Sample Data Inserts
-- -----------------------------

-- Users
INSERT INTO users (email, password_hash) VALUES
('alice@example.com', 'hash_pw1'),
('bob@example.com', 'hash_pw2'),
('carol@example.com', 'hash_pw3');

-- User Profiles
INSERT INTO user_profiles (user_id, first_name, last_name, phone, birth_date, bio) VALUES
(1, 'Alice', 'Johnson', '1234567890', '1990-05-15', 'Loyal customer and frequent shopper.'),
(2, 'Bob', 'Smith', '0987654321', '1985-07-20', 'Prefers electronics and gadgets.'),
(3, 'Carol', 'Miller', '5555555555', '1992-01-10', 'Enjoys fashion and lifestyle products.');

-- Addresses
INSERT INTO addresses (user_id, label, street, city, state, postal_code, country, is_primary) VALUES
(1, 'Home', '123 Main St', 'Nairobi', 'Nairobi County', '00100', 'Kenya', TRUE),
(2, 'Office', '456 Business Rd', 'Mombasa', 'Coast', '80100', 'Kenya', TRUE),
(3, 'Home', '789 Central Ave', 'Kisumu', 'Nyanza', '40100', 'Kenya', TRUE);

-- Suppliers
INSERT INTO suppliers (name, contact_email, phone) VALUES
('TechSource Ltd', 'contact@techsource.com', '+254700111222'),
('FashionHub Co', 'info@fashionhub.com', '+254700333444');

-- Categories
INSERT INTO categories (name, slug) VALUES
('Electronics', 'electronics'),
('Laptops', 'laptops'),
('Clothing', 'clothing'),
('Shoes', 'shoes');

-- Products
INSERT INTO products (sku, name, description, price, weight_kg, supplier_id) VALUES
('LAP-001', 'Dell Inspiron 15', '15-inch laptop with Intel i5 processor', 750.00, 2.2, 1),
('LAP-002', 'HP Pavilion 14', '14-inch laptop with AMD Ryzen 5', 680.00, 2.0, 1),
('CLO-001', 'Blue Denim Jacket', 'Stylish blue denim jacket for men', 55.00, 1.0, 2),
('SHO-001', 'Running Sneakers', 'Lightweight running sneakers', 75.00, 0.8, 2);

-- Product Categories (many-to-many)
INSERT INTO product_categories (product_id, category_id) VALUES
(1, 1), -- Dell Inspiron -> Electronics
(1, 2), -- Dell Inspiron -> Laptops
(2, 1), -- HP Pavilion -> Electronics
(2, 2), -- HP Pavilion -> Laptops
(3, 3), -- Denim Jacket -> Clothing
(4, 4); -- Sneakers -> Shoes

-- Warehouses
INSERT INTO warehouses (name, location) VALUES
('Main Warehouse', 'Nairobi'),
('Coastal Warehouse', 'Mombasa');

-- Inventory
INSERT INTO inventory (product_id, warehouse_id, quantity) VALUES
(1, 1, 50),  -- Dell Inspiron in Nairobi
(2, 1, 30),  -- HP Pavilion in Nairobi
(3, 2, 100), -- Denim Jacket in Mombasa
(4, 2, 60);  -- Sneakers in Mombasa

-- Orders
INSERT INTO orders (order_number, user_id, shipping_address_id, billing_address_id, total_amount, currency, status) VALUES
('ORD-1001', 1, 1, 1, 805.00, 'USD', 'paid'),
('ORD-1002', 2, 2, 2, 75.00, 'USD', 'pending');

-- Order Items
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 750.00), -- Dell Inspiron
(1, 3, 1, 55.00),  -- Denim Jacket
(2, 4, 1, 75.00);  -- Sneakers

-- Payments
INSERT INTO payments (order_id, paid_amount, method, provider_reference, status, paid_at) VALUES
(1, 805.00, 'card', 'TXN12345', 'completed', NOW());

-- Product Reviews
INSERT INTO product_reviews (product_id, user_id, rating, title, body) VALUES
(1, 1, 5, 'Great laptop!', 'Very fast and reliable.'),
(3, 2, 4, 'Nice jacket', 'Fits well and looks good.'),
(4, 3, 5, 'Awesome sneakers', 'Very comfortable for running.');
