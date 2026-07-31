-- STEP 9: Reusable Tools -- View & Stored Procedure
USE olist_ecommerce;

-- View: always-current seller performance summary
CREATE VIEW seller_performance AS
SELECT 
    s.seller_id,
    s.seller_city,
    s.seller_state,
    SUM(oi.price) AS total_revenue,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    AVG(r.review_score) AS avg_review_score
FROM sellers s
INNER JOIN order_items oi ON s.seller_id = oi.seller_id
INNER JOIN order_reviews r ON oi.order_id = r.order_id
GROUP BY s.seller_id, s.seller_city, s.seller_state;

-- Usage:
-- SELECT * FROM seller_performance ORDER BY total_revenue DESC LIMIT 10;

-- Stored Procedure: top 10 sellers by revenue within a custom date range
DELIMITER //

CREATE PROCEDURE top_sellers_by_date(IN start_date DATE, IN end_date DATE)
BEGIN
    SELECT 
        s.seller_id,
        s.seller_city,
        s.seller_state,
        SUM(oi.price) AS total_revenue,
        COUNT(DISTINCT oi.order_id) AS total_orders
    FROM sellers s
    INNER JOIN order_items oi ON s.seller_id = oi.seller_id
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_purchase_timestamp BETWEEN start_date AND end_date
    GROUP BY s.seller_id, s.seller_city, s.seller_state
    ORDER BY total_revenue DESC
    LIMIT 10;
END //

DELIMITER ;

-- Usage:
-- CALL top_sellers_by_date('2017-01-01', '2017-03-31');
