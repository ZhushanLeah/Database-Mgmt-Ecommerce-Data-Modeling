
   Assignment 6 - Transactions (ecommerce_db)
   Coherent with Assignment_5_Create_Database.sql schema + triggers.

   Triggers from assignment 5 that we used in our transactions
     - trg_validate_order_item_quantity (BEFORE INSERT ON Order_Item)
         * prevents ordering more than Product.stock_quantity
     - trg_update_product_stock (AFTER INSERT ON Order_Item)
         * reduces Product.stock_quantity automatically
     - trg_validate_payment_amount (BEFORE INSERT ON Order_Payment)
         * prevents payment_amount > SUM(Order_Item.total_price_per_product)
     - trg_update_order_status (AFTER INSERT ON Order_Payment)
         * sets "Order".order_status='processing' and approval date
--


-- 
-- TRANSACTION 1: Place a new order (INSERT + uses triggers)
--   1) INSERT into "Order"
--   2) INSERT into Order_Item (trigger validates quantity + reduces stock)
--   3) INSERT into Order_Payment (trigger validates amount + updates order status)
--  4) View-based verification

BEGIN;

-- Insert a new order for an existing customer (choose one with customer_id = 1 for simplicity).
 WITH chosen_customer AS (
    SELECT customer_id 
    FROM Customer
    ORDER BY customer_id
    LIMIT 1
),
new_order AS (
    SELECT COALESCE(MAX(order_id), 0) + 1 AS order_id
    FROM "Order"
)
INSERT INTO "Order" (
    order_id, customer_id, order_date, order_status,
    order_approval_date, order_delivery_date, order_estimation_delivery_date
)
SELECT
    no.order_id,
    cc.customer_id,
    CURRENT_DATE,
    'pending',
    NULL,
    NULL,
    CURRENT_DATE + INTERVAL '7 days'
FROM new_order no
CROSS JOIN chosen_customer cc;

-- Pick two products that have stock > 0, and choose a seller for each product
-- from historical Order_Item data (so seller_id exists and is coherent).
-- If a product was never sold before, we fall back to the smallest seller_id.
WITH new_order AS (
    SELECT MAX(order_id) AS order_id FROM "Order"
),
picks AS (
    SELECT
        p.product_id,
        -- Choose a seller that has sold this product before; otherwise min seller_id
        COALESCE(
            (SELECT oi.seller_id FROM Order_Item oi WHERE oi.product_id = p.product_id ORDER BY oi.order_id DESC LIMIT 1),
            (SELECT seller_id FROM Seller ORDER BY seller_id LIMIT 1)
        ) AS seller_id,
        1 AS quantity,
        p.product_price_per_unit AS unit_price
    FROM Product p
    WHERE p.stock_quantity > 0
    ORDER BY p.product_id
    LIMIT 2
)
INSERT INTO Order_Item (order_id, product_id, seller_id, quantity, total_price_per_product)
SELECT
    no.order_id,
    pk.product_id,
    pk.seller_id,
    pk.quantity,
    (pk.unit_price * pk.quantity)
FROM new_order no
JOIN picks pk ON TRUE;

-- Insert payment equal to the order item total.
-- Payment trigger will:
--   * validate payment_amount <= order total
--   * update "Order" status to 'processing'
WITH new_order AS (
    SELECT MAX(order_id) AS order_id FROM "Order"
),
order_total AS (
    SELECT
        oi.order_id,
        COALESCE(SUM(oi.total_price_per_product), 0) AS total_amount
    FROM Order_Item oi
    JOIN new_order no ON no.order_id = oi.order_id
    GROUP BY oi.order_id
),
new_payment AS (
    SELECT COALESCE(MAX(payment_id), 0) + 1 AS payment_id FROM Order_Payment
)
INSERT INTO Order_Payment (payment_id, payment_date, order_id, payment_type, payment_amount)
SELECT
    np.payment_id,
    CURRENT_DATE,
    ot.order_id,
    'credit_card',
    ot.total_amount
FROM order_total ot
CROSS JOIN new_payment np;

-- Verification using view (vw_order_summary should show the new order with correct status and totals)
SELECT *
FROM vw_order_summary
WHERE order_id = (SELECT MAX(order_id) FROM "Order");

COMMIT;



-- 
-- TRANSACTION 2: Update order lifecycle (UPDATE)
-- Example: mark an order as shipped and set approval date if missing
-- (Uses UPDATE requirement with realistic business logic.)
-- 

BEGIN;

-- Target the latest order (the one created above).
WITH target AS (
    SELECT MAX(order_id) AS order_id FROM "Order"
)
UPDATE "Order" o
SET
    order_status = 'shipped',
    order_approval_date = COALESCE(o.order_approval_date, CURRENT_DATE)
FROM target t
WHERE o.order_id = t.order_id
  AND o.order_status IN ('pending', 'processing');

-- Verify
SELECT *
FROM vw_order_summary
WHERE order_id = (SELECT MAX(order_id) FROM "Order");

COMMIT;



-- 
-- TRANSACTION 3: Cancel an order and restock (DELETE + UPDATE)
--   1) Identify an order to cancel (latest order)
--   2) Restock products from its Order_Item lines (since stock was reduced on insert)
--   3) DELETE the order (cascades delete Order_Item, Order_Payment, Order_Review)
-- 

BEGIN;

-- Choose the latest order again
WITH target AS (
    SELECT MAX(order_id) AS order_id FROM "Order"
),
lines AS (
    SELECT oi.product_id, SUM(oi.quantity) AS qty
    FROM Order_Item oi
    JOIN target t ON t.order_id = oi.order_id
    GROUP BY oi.product_id
)
-- Lock products first to prevent concurrent changes
SELECT p.product_id
FROM Product p
JOIN lines l ON l.product_id = p.product_id
FOR UPDATE;

-- Restock each product
WITH target AS (
    SELECT MAX(order_id) AS order_id FROM "Order"
),
lines AS (
    SELECT oi.product_id, SUM(oi.quantity) AS qty
    FROM Order_Item oi
    JOIN target t ON t.order_id = oi.order_id
    GROUP BY oi.product_id
)
UPDATE Product p
SET stock_quantity = p.stock_quantity + l.qty
FROM lines l
WHERE p.product_id = l.product_id;

-- Now delete the order (cascades via FK ON DELETE CASCADE)
DELETE FROM "Order"
WHERE order_id = (SELECT MAX(order_id) FROM "Order");

COMMIT;



/* 
   Optional extra: demonstrate rollback behavior (safe demo)
   This transaction tries to overpay and will FAIL, then ROLLBACK.
   Keep it commented if you don't want intentional failure in grading.
 */

-- BEGIN;
-- -- Pick an existing order_id (smallest) that has items
-- WITH t AS (
--     SELECT o.order_id
--     FROM "Order" o
--     JOIN Order_Item oi ON oi.order_id = o.order_id
--     ORDER BY o.order_id
--     LIMIT 1
-- ),
-- new_payment AS (
--     SELECT COALESCE(MAX(payment_id), 0) + 1 AS payment_id FROM Order_Payment
-- ),
-- total AS (
--     SELECT t.order_id, SUM(oi.total_price_per_product) AS order_total
--     FROM t
--     JOIN Order_Item oi ON oi.order_id = t.order_id
--     GROUP BY t.order_id
-- )
-- INSERT INTO Order_Payment(payment_id, payment_date, order_id, payment_type, payment_amount)
-- SELECT np.payment_id, CURRENT_DATE, tot.order_id, 'credit_card', tot.order_total + 9999
-- FROM new_payment np, total tot;
--
-- -- This will never run because the trigger raises EXCEPTION
-- COMMIT;
--
-- -- If you run manually in a client, use:
-- -- ROLLBACK;
