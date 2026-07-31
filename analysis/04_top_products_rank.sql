-- STEP 4: Window Function -- Top 5 Products per Category (DENSE_RANK)
USE olist_ecommerce;

WITH ProdRank AS (
    SELECT 
        pc.product_category_name_english,
        oi.product_id,
        SUM(oi.price) AS product_revenue,
        DENSE_RANK() OVER (
            PARTITION BY pc.product_category_name_english 
            ORDER BY SUM(oi.price) DESC
        ) AS RevRank
    FROM order_items oi
    INNER JOIN products p ON oi.product_id = p.product_id
    INNER JOIN product_category_translation pc ON p.product_category_name = pc.product_category_name
    GROUP BY pc.product_category_name_english, oi.product_id
)
SELECT 
    product_category_name_english,
    product_id,
    product_revenue,
    RevRank
FROM ProdRank
WHERE RevRank <= 5
ORDER BY product_category_name_english, RevRank;
-- DENSE_RANK chosen over RANK/ROW_NUMBER so tied products aren't skipped from the top-5 list.
