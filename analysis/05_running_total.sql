-- STEP 5: Running Total -- Cumulative Monthly Revenue
USE olist_ecommerce;

WITH RunTotal AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS Month,
        SUM(oi.price) AS Revenue
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
)
SELECT 
    Month,
    Revenue,
    SUM(Revenue) OVER (ORDER BY Month) AS running_total
FROM RunTotal
ORDER BY Month;
-- SUM() OVER (ORDER BY x) with no PARTITION BY produces a cumulative running total,
-- since the "window" for each row defaults to "this row and everything before it."
