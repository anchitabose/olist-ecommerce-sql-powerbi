-- STEP 8: Recursive CTE -- Zero-Order Month Detection
USE olist_ecommerce;

WITH RECURSIVE calendar AS (
    -- Anchor: earliest order month
    SELECT DATE_FORMAT(MIN(order_purchase_timestamp), '%Y-%m-01') AS month_start
    FROM orders
    
    UNION ALL
    
    -- Recursive: keep adding 1 month until past the latest order date
    SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)
    FROM calendar
    WHERE month_start < (SELECT MAX(order_purchase_timestamp) FROM orders)
),
actual_orders AS (
    SELECT 
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01') AS order_month,
        COUNT(*) AS num_orders
    FROM orders
    GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01')
)
SELECT 
    cal.month_start,
    COALESCE(ao.num_orders, 0) AS num_orders
FROM calendar cal
LEFT JOIN actual_orders ao ON cal.month_start = ao.order_month
ORDER BY cal.month_start;

-- Finding: two zero-order months detected --
-- 2016-11: platform's pre-launch/soft-launch phase (real business gap)
-- 2018-11: data extraction artifact (dataset ends 2018-10-17, not a real gap)
