-- STEP 2: Revenue Aggregation (Category + Monthly)
USE olist_ecommerce;

-- Part A: Revenue by category
SELECT pc.product_category_name_english, SUM(oi.price) AS revenue
FROM order_items oi
INNER JOIN products p ON oi.product_id = p.product_id
INNER JOIN product_category_translation pc ON p.product_category_name = pc.product_category_name
GROUP BY pc.product_category_name_english
ORDER BY revenue DESC;
-- Finding: Top categories -- health_beauty (1,258,681.34), watches_gifts (1,205,005.68),
-- bed_bath_table (1,036,988.68), sports_leisure, computers_accessories, furniture_decor...

-- Part B: Revenue by month
SELECT DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m') AS Month, SUM(oi.price) AS Revenue
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY Month;
-- Finding: Near-zero revenue in late 2016 (soft launch phase), steady growth through 2017,
-- peaking in November 2017 (~1,010,271) -- consistent with Black Friday seasonality.
