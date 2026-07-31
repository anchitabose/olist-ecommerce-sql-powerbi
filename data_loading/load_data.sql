-- Data Loading Script
-- Replace 'C:/path/to/your/csvs/' with your actual folder path
-- Run in this exact order (parents before children, due to foreign keys)

USE olist_ecommerce;

-- Prerequisite (run once): enable local file loading
-- SET GLOBAL local_infile = 1;
-- Also add OPT_LOCAL_INFILE=1 under Workbench connection's Advanced "Others" box,
-- then reconnect.

-- 1. customers
LOAD DATA LOCAL INFILE 'C:\Users\HP\Downloads\SQL Dataset\olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state);

-- 2. sellers
LOAD DATA LOCAL INFILE 'C:\Users\HP\Downloads\SQL Dataset\olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS
(seller_id, seller_zip_code_prefix, seller_city, seller_state);

-- 3. product_category_translation (note: \r\n line ending in raw file)
LOAD DATA LOCAL INFILE 'C:\Users\HP\Downloads\SQL Dataset\product_category_name_translation.csv'
INTO TABLE product_category_translation
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 ROWS
(product_category_name, product_category_name_english);

-- 4. products (NULLIF pattern handles blank numeric fields)
LOAD DATA LOCAL INFILE 'C:\Users\HP\Downloads\SQL Dataset\olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS
(product_id, @cat, @nlen, @dlen, @photos, @weight, @len, @height, @width)
SET
  product_category_name = NULLIF(@cat, ''),
  product_name_length = NULLIF(@nlen, ''),
  product_description_length = NULLIF(@dlen, ''),
  product_photos_qty = NULLIF(@photos, ''),
  product_weight_g = NULLIF(@weight, ''),
  product_length_cm = NULLIF(@len, ''),
  product_height_cm = NULLIF(@height, ''),
  product_width_cm = NULLIF(@width, '');

-- 5. orders (NULLIF pattern handles blank date fields, e.g. undelivered orders)
LOAD DATA LOCAL INFILE 'C:\Users\HP\Downloads\SQL Dataset\olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS
(order_id, customer_id, order_status, @pur, @app, @carr, @deliv, @est)
SET
  order_purchase_timestamp = NULLIF(@pur, ''),
  order_approved_at = NULLIF(@app, ''),
  order_delivered_carrier_date = NULLIF(@carr, ''),
  order_delivered_customer_date = NULLIF(@deliv, ''),
  order_estimated_delivery_date = NULLIF(@est, '');

-- 6. order_items
LOAD DATA LOCAL INFILE 'C:\Users\HP\Downloads\SQL Dataset\olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS
(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value);

-- 7. order_payments
LOAD DATA LOCAL INFILE 'C:\Users\HP\Downloads\SQL Dataset\olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS
(order_id, payment_sequential, payment_type, payment_installments, payment_value);

-- 8. order_reviews (note: \r\n line ending; title/message often blank)
LOAD DATA LOCAL INFILE 'C:\Users\HP\Downloads\SQL Dataset\olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 ROWS
(review_id, order_id, review_score, @title, @msg, review_creation_date, review_answer_timestamp)
SET
  review_comment_title = NULLIF(@title, ''),
  review_comment_message = NULLIF(@msg, '');

-- 9. geolocation (large file, ~1M rows -- character set matters due to accented city names)
-- NOTE: if re-running, TRUNCATE TABLE geolocation first to avoid duplicate rows,
-- since this table has no primary key to prevent duplicates.
LOAD DATA LOCAL INFILE 'C:\Users\HP\Downloads\SQL Dataset\olist_geolocation_dataset.csv'
INTO TABLE geolocation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS
(geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state);

-- Verification: expected row counts
-- customers ~99,441 | sellers ~3,095 | products ~32,951 | product_category_translation ~71
-- orders ~99,441 | order_items ~112,650 | order_payments ~103,886
-- order_reviews ~99,223 (1 row truncated due to embedded delimiter in review text)
-- geolocation ~1,000,163
SELECT 'customers' AS tbl, COUNT(*) AS rows FROM customers
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'product_category_translation', COUNT(*) FROM product_category_translation
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'geolocation', COUNT(*) FROM geolocation;
