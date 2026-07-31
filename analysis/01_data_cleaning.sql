-- STEP 1: Data Cleaning / Quality Audit
USE olist_ecommerce;

-- Check 1: Nulls in key date fields
SELECT 
  SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS null_approved,
  SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_delivered,
  COUNT(*) AS total_orders
FROM orders;
-- Finding: 160 null_approved, 2,965 null_delivered out of 99,441 total.

-- Check 2: Order status distribution
SELECT order_status, COUNT(*) AS cnt
FROM orders
GROUP BY order_status
ORDER BY cnt DESC;
-- Finding: delivered 96,478 | shipped 1,107 | canceled 625 | unavailable 609
-- invoiced 314 | processing 301 | created 5 | approved 2
-- Confirms null_delivered corresponds almost exactly to non-delivered statuses.

-- Check 3: Duplicate customers (customer_id vs customer_unique_id)
SELECT customer_unique_id, COUNT(*) AS cnt
FROM customers
GROUP BY customer_unique_id
HAVING cnt > 1
ORDER BY cnt DESC
LIMIT 10;
-- Finding: customer_id is order-scoped, not person-scoped. Top repeat customer
-- (8d50f5eadf50201ccdcedfb9e2ac8455) placed 17 orders under 17 different customer_ids.
-- All customer-level analysis must group by customer_unique_id.

-- Check 4: Products missing category
SELECT COUNT(*) AS products_missing_category
FROM products
WHERE product_category_name IS NULL;
-- Finding: 610 products (1.9%) missing category.

-- Check 5: Orders with items but no matching payment (anti-join pattern)
SELECT oi.order_id
FROM order_items oi
LEFT JOIN order_payments op ON oi.order_id = op.order_id
WHERE op.order_id IS NULL;
-- Finding: 3 orphan orders (0.003%) -- likely data extraction artifact.
