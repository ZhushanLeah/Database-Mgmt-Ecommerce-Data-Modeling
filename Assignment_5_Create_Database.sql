-- Database: PostgreSQL 14+
-- Based on ERD containing Customer, Order, Order_Item, Product, Product_Category,
--               Seller, Geolocation, Order_Payment, and Order_Review entities

--CREATE DATABASE
CREATE DATABASE ecommerce_db;

-- TABLE CREATION WITH CONSTRAINTS
-- Table: Geolocation
-- Master data for geographic locations
CREATE TABLE Geolocation (
    geo_zip_code INTEGER NOT NULL,
    geo_longitude FLOAT,
    geo_latitude FLOAT,
    geo_city VARCHAR(100),
    geo_state VARCHAR(50),
    CONSTRAINT pk_geolocation PRIMARY KEY (geo_zip_code),
    CONSTRAINT chk_geo_longitude CHECK (geo_longitude BETWEEN -180 AND 180),
    CONSTRAINT chk_geo_latitude CHECK (geo_latitude BETWEEN -90 AND 90)
);

-- Table: Product_Category
-- Product categories master data
CREATE TABLE Product_Category (
    product_category_id INTEGER NOT NULL,
    product_category_name VARCHAR(100) NOT NULL,
    CONSTRAINT pk_product_category PRIMARY KEY (product_category_id),
    CONSTRAINT uq_category_name UNIQUE (product_category_name),
    CONSTRAINT chk_category_name_length CHECK (LENGTH(product_category_name) >= 3)
);

-- Table: Seller
-- Seller/vendor information
CREATE TABLE Seller (
    seller_id INTEGER NOT NULL,
    seller_zip_code INTEGER NOT NULL,
    seller_name VARCHAR(100),
    CONSTRAINT pk_seller PRIMARY KEY (seller_id),
    CONSTRAINT fk_seller_geolocation 
        FOREIGN KEY (seller_zip_code) 
        REFERENCES Geolocation(geo_zip_code)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Table: Customer
-- Customer information
CREATE TABLE Customer (
    customer_id INTEGER NOT NULL,
    customer_zip_code INTEGER NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    CONSTRAINT pk_customer PRIMARY KEY (customer_id),
    CONSTRAINT fk_customer_geolocation 
        FOREIGN KEY (customer_zip_code) 
        REFERENCES Geolocation(geo_zip_code)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_customer_name_not_empty CHECK (TRIM(customer_name) <> '')
);

-- Table: Product
-- Product catalog
CREATE TABLE Product (
    product_id INTEGER NOT NULL,
    product_category_id INTEGER NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_price_per_unit FLOAT NOT NULL,
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT pk_product PRIMARY KEY (product_id),
    CONSTRAINT fk_product_category 
        FOREIGN KEY (product_category_id) 
        REFERENCES Product_Category(product_category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_product_price_positive CHECK (product_price_per_unit > 0),
    CONSTRAINT chk_stock_non_negative CHECK (stock_quantity >= 0)
);

-- Table: Order
-- Customer orders
CREATE TABLE "Order" (
    order_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    order_date DATE NOT NULL,
    order_status VARCHAR(50) NOT NULL DEFAULT 'pending',
    order_approval_date DATE,
    order_delivery_date DATE,
    order_estimation_delivery_date DATE,
    CONSTRAINT pk_order PRIMARY KEY (order_id),
    CONSTRAINT fk_order_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES Customer(customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_order_status CHECK (order_status IN 
        ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    CONSTRAINT chk_order_dates CHECK (
        order_approval_date IS NULL OR order_approval_date >= order_date
    ),
    CONSTRAINT chk_delivery_dates CHECK (
        order_delivery_date IS NULL OR 
        order_estimation_delivery_date IS NULL OR
        order_delivery_date >= order_date
    )
);

-- Table: Order_Item
-- Order line items (products in each order)
CREATE TABLE Order_Item (
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    seller_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    total_price_per_product NUMERIC(10,2) NOT NULL,
    CONSTRAINT pk_order_item PRIMARY KEY (order_id, product_id, seller_id),
    CONSTRAINT fk_order_item_order 
        FOREIGN KEY (order_id) 
        REFERENCES "Order"(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_order_item_product 
        FOREIGN KEY (product_id) 
        REFERENCES Product(product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_order_item_seller 
        FOREIGN KEY (seller_id) 
        REFERENCES Seller(seller_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_total_price_positive CHECK (total_price_per_product > 0)
);

-- Table: Order_Payment
-- Payment information for orders
CREATE TABLE Order_Payment (
    payment_id INTEGER NOT NULL,
    payment_date DATE NOT NULL,
    order_id INTEGER NOT NULL,
    payment_type VARCHAR(50) NOT NULL,
    payment_amount FLOAT NOT NULL,
    CONSTRAINT pk_order_payment PRIMARY KEY (payment_id),
    CONSTRAINT fk_payment_order 
        FOREIGN KEY (order_id) 
        REFERENCES "Order"(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_payment_amount_positive CHECK (payment_amount > 0),
    CONSTRAINT chk_payment_type CHECK (payment_type IN 
        ('credit_card', 'debit_card', 'boleto', 'voucher', 'pix'))
);

-- Table: Order_Review
-- Customer reviews for orders
CREATE TABLE Order_Review (
    order_id INTEGER NOT NULL,
    order_review_date DATE NOT NULL,
    order_review_score INTEGER NOT NULL,
    order_review_comment VARCHAR(500),
    CONSTRAINT pk_order_review PRIMARY KEY (order_id),
    CONSTRAINT fk_review_order 
        FOREIGN KEY (order_id) 
        REFERENCES "Order"(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_review_score CHECK (order_review_score BETWEEN 1 AND 5)
);

-- CREATE INDEX
-- Following syntax will create secondary index. Unique Primary Index (UPI) is automatically created on primary key column(s) of each table.
CREATE INDEX idx_seller_zip_code ON Seller(seller_zip_code);
CREATE INDEX idx_customer_name ON Customer(customer_name);
CREATE INDEX idx_customer_zip_code ON Customer(customer_zip_code);
CREATE INDEX idx_product_category ON Product(product_category_id);
CREATE INDEX idx_product_name ON Product(product_name);
CREATE INDEX idx_order_customer ON "Order"(customer_id);
CREATE INDEX idx_order_date ON "Order"(order_date);
CREATE INDEX idx_order_status ON "Order"(order_status);
CREATE INDEX idx_order_item_product ON Order_Item(product_id);
CREATE INDEX idx_order_item_seller ON Order_Item(seller_id);
CREATE INDEX idx_payment_order ON Order_Payment(order_id);
CREATE INDEX idx_payment_date ON Order_Payment(payment_date);

-- TRIGGERS
-- Trigger 1: Update Order Status When Payment Received
CREATE OR REPLACE FUNCTION fn_update_order_status()
RETURNS TRIGGER AS $$
BEGIN
    -- When payment is recorded, update order status to 'processing'
    UPDATE "Order"
    SET order_status = 'processing',
        order_approval_date = NEW.payment_date
    WHERE order_id = NEW.order_id
      AND order_status = 'pending';
    
    RAISE NOTICE 'Order % status updated to processing after payment', NEW.order_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_order_status
AFTER INSERT ON Order_Payment
FOR EACH ROW
EXECUTE FUNCTION fn_update_order_status();

-- Trigger 2: Validate Order Item Quantity Against Stock
CREATE OR REPLACE FUNCTION fn_validate_order_item_quantity()
RETURNS TRIGGER AS $$
DECLARE
    available_stock INTEGER;
BEGIN
    -- Check current stock quantity
    SELECT stock_quantity INTO available_stock
    FROM Product
    WHERE product_id = NEW.product_id;
    
    -- Raise exception if insufficient stock
    IF available_stock < NEW.quantity THEN
        RAISE EXCEPTION 'Insufficient stock for product %. Available: %, Requested: %',
            NEW.product_id, available_stock, NEW.quantity;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_order_item_quantity
BEFORE INSERT ON Order_Item
FOR EACH ROW
EXECUTE FUNCTION fn_validate_order_item_quantity();

-- Trigger 3: Update Product Stock When Order Item Added
CREATE OR REPLACE FUNCTION fn_update_product_stock()
RETURNS TRIGGER AS $$
BEGIN
    -- Decrease stock quantity when order item is created
    UPDATE Product
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE product_id = NEW.product_id;
    
    RAISE NOTICE 'Stock reduced by % for product %', NEW.quantity, NEW.product_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_product_stock
AFTER INSERT ON Order_Item
FOR EACH ROW
EXECUTE FUNCTION fn_update_product_stock();

-- ASSERTION
-- Note: PostgreSQL does not support CREATE ASSERTION directly. We implement assertions using CHECK constraints and triggers.

-- Assertion: Payment amount should not exceed total order amount
CREATE OR REPLACE FUNCTION fn_validate_payment_amount()
RETURNS TRIGGER AS $$
DECLARE
    total_order_amount NUMERIC(10,2);
BEGIN
    -- Calculate total order amount
    SELECT COALESCE(SUM(total_price_per_product), 0)
    INTO total_order_amount
    FROM Order_Item
    WHERE order_id = NEW.order_id;
    
    -- Check if payment amount exceeds order total
    IF NEW.payment_amount > total_order_amount THEN
        RAISE EXCEPTION 'Payment amount (%) exceeds order total (%) for order %',
            NEW.payment_amount, total_order_amount, NEW.order_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_payment_amount
BEFORE INSERT OR UPDATE ON Order_Payment
FOR EACH ROW
EXECUTE FUNCTION fn_validate_payment_amount();

-- VIEWS
-- View 1: Order Summary with Customer and Payment Details
CREATE OR REPLACE VIEW vw_order_summary AS
SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    c.customer_id,
    c.customer_name,
    g.geo_city as customer_city,
    g.geo_state as customer_state,
    COUNT(DISTINCT oi.product_id) as total_products,
    SUM(oi.quantity) as total_items,
    ROUND(SUM(oi.total_price_per_product)::NUMERIC, 2) as order_total,
    op.payment_date,
    op.payment_type,
    op.payment_amount,
    CASE 
        WHEN o.order_delivery_date IS NOT NULL THEN 'Delivered'
        WHEN o.order_status = 'shipped' THEN 'In Transit'
        WHEN o.order_status = 'processing' THEN 'Processing'
        WHEN o.order_status = 'pending' THEN 'Pending Payment'
        ELSE 'Other'
    END as delivery_status
FROM "Order" o
JOIN Customer c ON o.customer_id = c.customer_id
JOIN Geolocation g ON c.customer_zip_code = g.geo_zip_code
LEFT JOIN Order_Item oi ON o.order_id = oi.order_id
LEFT JOIN Order_Payment op ON o.order_id = op.order_id
GROUP BY o.order_id, c.customer_id, c.customer_name, 
         g.geo_city, g.geo_state, op.payment_date, 
         op.payment_type, op.payment_amount;

-- View 2: Product Sales Performance
CREATE OR REPLACE VIEW vw_product_sales AS
SELECT 
    p.product_id,
    p.product_name,
    pc.product_category_name,
    p.product_price_per_unit,
    p.stock_quantity,
    COUNT(DISTINCT oi.order_id) as times_ordered,
    COALESCE(SUM(oi.quantity), 0) as total_quantity_sold,
    ROUND(COALESCE(SUM(oi.total_price_per_product), 0)::NUMERIC, 2) as total_revenue,
    ROUND(COALESCE(AVG(oi.total_price_per_product), 0)::NUMERIC, 2) as avg_order_value,
    CASE 
        WHEN p.stock_quantity = 0 THEN 'Out of Stock'
        WHEN p.stock_quantity < 10 THEN 'Low Stock'
        WHEN p.stock_quantity < 50 THEN 'Medium Stock'
        ELSE 'Well Stocked'
    END as stock_status
FROM Product p
JOIN Product_Category pc ON p.product_category_id = pc.product_category_id
LEFT JOIN Order_Item oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, pc.product_category_name,
         p.product_price_per_unit, p.stock_quantity
ORDER BY total_revenue DESC;
