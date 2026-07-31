-- STEP 6: Cohort Retention Analysis
USE olist_ecommerce;

WITH customer_orders AS (
  SELECT
    c.customer_unique_id,
    DATE_FORMAT(MIN(o.order_purchase_timestamp) OVER (PARTITION BY c.customer_unique_id), '%Y-%m') AS first_order_month,
    TIMESTAMPDIFF(MONTH, 
      MIN(o.order_purchase_timestamp) OVER (PARTITION BY c.customer_unique_id),  
      o.order_purchase_timestamp
    ) AS months_since_first_order
  FROM orders o
  INNER JOIN customers c ON o.customer_id = c.customer_id
)
SELECT 
  first_order_month,
  months_since_first_order,
  COUNT(DISTINCT customer_unique_id) AS num_customers
FROM customer_orders
GROUP BY first_order_month, months_since_first_order
ORDER BY first_order_month, months_since_first_order;

-- Finding: severe drop-off across nearly every cohort.
-- E.g. Jan 2017 cohort: 764 customers acquired (month 0), only 2 returned month 1.
-- Confirms Olist's business is driven overwhelmingly by one-time buyers.
