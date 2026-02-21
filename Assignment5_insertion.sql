  Assignment 5: Data Insertion Script
  Description: Inserts at least 10 tuples per relation respecting all FK constraints and triggers.

--LEVEL 1: Tables with NO Foreign Keys (Must be inserted first)

--1. Insert into Geolocation (10 tuples)
INSERT INTO Geolocation (geo_zip_code, geo_longitude, geo_latitude, geo_city, geo_state) VALUES
(10001, -74.0060, 40.7128, 'New York', 'NY'),
(10002, -73.9870, 40.7180, 'New York', 'NY'),
(20001, -77.0369, 38.9072, 'Washington', 'DC'),
(20002, -76.9900, 38.9000, 'Washington', 'DC'),
(30001, -84.3880, 33.7490, 'Atlanta', 'GA'),
(30002, -84.3900, 33.7500, 'Atlanta', 'GA'),
(40001, -85.7585, 38.2527, 'Louisville', 'KY'),
(40002, -85.7600, 38.2600, 'Louisville', 'KY'),
(50001, -93.6208, 41.5908, 'Des Moines', 'IA'),
(50002, -93.6300, 41.6000, 'Des Moines', 'IA');

--2. Insert into Product_Category (10 tuples)
INSERT INTO Product_Category (product_category_id, product_category_name) VALUES
(1, 'Electronics'),
(2, 'Computers'),
(3, 'Smartphones'),
(4, 'Accessories'),
(5, 'Home Appliances'),
(6, 'Books'),
(7, 'Clothing'),
(8, 'Sports'),
(9, 'Toys'),
(10, 'Beauty');

--LEVEL 2: Tables that depend on Level 1

--3. Insert into Seller (10 tuples)
INSERT INTO Seller (seller_id, seller_zip_code, seller_name) VALUES
(1, 10001, 'Tech Store NY'),
(2, 10002, 'Gadget Hub'),
(3, 20001, 'Capital Electronics'),
(4, 20002, 'DC Books'),
(5, 30001, 'Atlanta Fashion'),
(6, 30002, 'Southern Sports'),
(7, 40001, 'Louisville Toys'),
(8, 40002, 'KY Beauty'),
(9, 50001, 'Midwest Appliances'),
(10, 50002, 'Iowa Accessories');

--4. Insert into Customer (10 tuples)
INSERT INTO Customer (customer_id, customer_zip_code, customer_name) VALUES
(1, 10001, 'Alice Smith'),
(2, 10002, 'Bob Jones'),
(3, 20001, 'Charlie Brown'),
(4, 20002, 'Diana Prince'),
(5, 30001, 'Ethan Hunt'),
(6, 30002, 'Fiona Gallagher'),
(7, 40001, 'George Lucas'),
(8, 40002, 'Hannah Abbott'),
(9, 50001, 'Ian Malcolm'),
(10, 50002, 'Julia Roberts');

--5. Insert into Product (10 tuples)
--Stock is set to 100 so that Trigger 2 & 3 can safely deduct quantity without errors.
INSERT INTO Product (product_id, product_category_id, product_name, product_price_per_unit, stock_quantity) VALUES
(1, 1, '4K Smart TV', 500.00, 100),
(2, 2, 'Laptop Pro', 1200.00, 100),
(3, 3, 'Smartphone X', 800.00, 100),
(4, 4, 'Wireless Mouse', 25.00, 100),
(5, 5, 'Microwave Oven', 150.00, 100),
(6, 6, 'Database Systems Book', 85.00, 100),
(7, 7, 'Cotton T-Shirt', 20.00, 100),
(8, 8, 'Yoga Mat', 30.00, 100),
(9, 9, 'Lego Set', 60.00, 100),
(10, 10, 'Face Serum', 40.00, 100);

--LEVEL 3: Tables that depend on Level 2

--6. Insert into "Order" (10 tuples)
--Status is strictly 'pending' to allow Trigger 1 to update it later.
INSERT INTO "Order" (order_id, customer_id, order_date, order_status, order_estimation_delivery_date) VALUES
(1, 1, '2026-01-01', 'pending', '2026-01-10'),
(2, 2, '2026-01-02', 'pending', '2026-01-11'),
(3, 3, '2026-01-03', 'pending', '2026-01-12'),
(4, 4, '2026-01-04', 'pending', '2026-01-13'),
(5, 5, '2026-01-05', 'pending', '2026-01-14'),
(6, 6, '2026-01-06', 'pending', '2026-01-15'),
(7, 7, '2026-01-07', 'pending', '2026-01-16'),
(8, 8, '2026-01-08', 'pending', '2026-01-17'),
(9, 9, '2026-01-09', 'pending', '2026-01-18'),
(10, 10, '2026-01-10', 'pending', '2026-01-19');

LEVEL 4: Tables that depend on Level 3 (and trigger complex validations)

--7. Insert into Order_Item (10 tuples)
--This action fires Trigger 2 (Stock Check) and Trigger 3 (Stock Deduction).
INSERT INTO Order_Item (order_id, product_id, seller_id, quantity, total_price_per_product) VALUES
(1, 1, 1, 1, 500.00),
(2, 2, 2, 1, 1200.00),
(3, 3, 3, 2, 1600.00),
(4, 4, 4, 1, 25.00),
(5, 5, 5, 1, 150.00),
(6, 6, 6, 3, 255.00),
(7, 7, 7, 2, 40.00),
(8, 8, 8, 1, 30.00),
(9, 9, 9, 1, 60.00),
(10, 10, 10, 1, 40.00);

--8. Insert into Order_Payment (10 tuples)
--Payment amounts match exactly with Order_Item to pass the Trigger 4 Assertion.
--payment_date is greater than order_date to pass the tuple CHECK constraint in "Order" table when Trigger 1 fires.
INSERT INTO Order_Payment (payment_id, payment_date, order_id, payment_type, payment_amount) VALUES
(1, '2026-01-02', 1, 'credit_card', 500.00),
(2, '2026-01-03', 2, 'pix', 1200.00),
(3, '2026-01-04', 3, 'boleto', 1600.00),
(4, '2026-01-05', 4, 'debit_card', 25.00),
(5, '2026-01-06', 5, 'voucher', 150.00),
(6, '2026-01-07', 6, 'credit_card', 255.00),
(7, '2026-01-08', 7, 'pix', 40.00),
(8, '2026-01-09', 8, 'boleto', 30.00),
(9, '2026-01-10', 9, 'debit_card', 60.00),
(10, '2026-01-11', 10, 'credit_card', 40.00);

--9. Insert into Order_Review (10 tuples)
INSERT INTO Order_Review (order_id, order_review_date, order_review_score, order_review_comment) VALUES
(1, '2026-01-12', 5, 'Excellent TV, fast shipping!'),
(2, '2026-01-13', 4, 'Good laptop, slightly heavy.'),
(3, '2026-01-14', 5, 'Love the phone, amazing camera.'),
(4, '2026-01-15', 3, 'Average mouse, does the job.'),
(5, '2026-01-16', 5, 'Works perfectly, heats fast.'),
(6, '2026-01-17', 4, 'Very informative textbook.'),
(7, '2026-01-18', 5, 'Super comfortable cotton.'),
(8, '2026-01-19', 4, 'Good yoga mat, no slip.'),
(9, '2026-01-20', 5, 'Kids loved this Lego set!'),
(10, '2026-01-21', 4, 'Smells nice, skin feels soft.');