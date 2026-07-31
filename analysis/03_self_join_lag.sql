-- STEP 3: Self-Join & LAG() -- Time Between Orders
USE olist_ecommerce;

-- Approach A: Self-join (every earlier-order/later-order pair per customer)
SELECT 
  a.customer_unique_id,
  a.order_purchase_timestamp AS first_order,
  b.order_purchase_timestamp AS next_order,
  DATEDIFF(b.order_purchase_timestamp, a.order_purchase_timestamp) AS days_between
FROM 
  (SELECT o.order_id, c.customer_unique_id, o.order_purchase_timestamp
   FROM orders o INNER JOIN customers c ON o.customer_id = c.customer_id) AS a
INNER JOIN 
  (SELECT o.order_id, c.customer_unique_id, o.order_purchase_timestamp
   FROM orders o INNER JOIN customers c ON o.customer_id = c.customer_id) AS b
ON a.customer_unique_id = b.customer_unique_id
AND a.order_purchase_timestamp < b.order_purchase_timestamp;
-- Note: produces ALL pairwise comparisons, not just consecutive orders.
-- For a customer with 17 orders, produces 17*16/2 = 136 rows.

-- Approach B: LAG() -- only consecutive order pairs (the more standard business metric)
SELECT 
  c.customer_unique_id,
  o.order_purchase_timestamp,
  DATEDIFF(
    o.order_purchase_timestamp,
    LAG(o.order_purchase_timestamp) OVER (
      PARTITION BY c.customer_unique_id 
      ORDER BY o.order_purchase_timestamp
    )
  ) AS days_since_last_order
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY c.customer_unique_id, o.order_purchase_timestamp;
-- First order per customer shows NULL (no previous order to compare against) -- expected.

-- Average gap between consecutive repeat purchases (excludes one-time buyers' NULLs)
WITH order_gaps AS (
  SELECT 
    c.customer_unique_id,
    DATEDIFF(
      o.order_purchase_timestamp,
      LAG(o.order_purchase_timestamp) OVER (
        PARTITION BY c.customer_unique_id 
        ORDER BY o.order_purchase_timestamp
      )
    ) AS days_since_last_order
  FROM orders o
  INNER JOIN customers c ON o.customer_id = c.customer_id
)
SELECT AVG(days_since_last_order)
FROM order_gaps
WHERE days_since_last_order IS NOT NULL;
-- Finding: average gap = 78.2257 days (~2.5 months) among repeat customers.
