-- STEP 7: RFM Segmentation (Recency, Frequency, Monetary)
USE olist_ecommerce;

-- Reference date used as "today" (latest order date in the dataset)
-- SELECT MAX(order_purchase_timestamp) FROM orders;  --> 2018-10-17

WITH rfm_base AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF('2018-10-17', MAX(o.order_purchase_timestamp)) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT
        customer_unique_id,
        recency, frequency, monetary,
        -- Recency: smaller = better, so sort DESC (worst first -> bucket 1, best last -> bucket 5)
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        -- Frequency: NTILE is unreliable here since ~97% of customers share frequency = 1,
        -- causing arbitrary tie-splitting. A business-rule CASE statement is used instead.
        CASE 
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 3
            WHEN frequency >= 3 THEN 5
        END AS f_score,
        -- Monetary: bigger = better, so sort ASC (worst first -> bucket 1, best last -> bucket 5)
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),
rfm_avg AS (
    SELECT
        customer_unique_id,
        recency, frequency, monetary,
        r_score, f_score, m_score,
        (r_score + f_score + m_score) / 3 AS avg_score
    FROM rfm_scores
),
rfm_final AS (
    SELECT
        customer_unique_id,
        recency, frequency, monetary,
        r_score, f_score, m_score,
        avg_score,
        CASE 
            WHEN avg_score >= 4 THEN 'Champion'
            WHEN avg_score >= 3 THEN 'Loyal Customer'
            WHEN avg_score >= 2 THEN 'At Risk'
            ELSE 'Lost'
        END AS customer_tier
    FROM rfm_avg
)
SELECT * FROM rfm_final;

-- Tier summary counts
WITH rfm_base AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF('2018-10-17', MAX(o.order_purchase_timestamp)) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT
        customer_unique_id,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        CASE 
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 3
            WHEN frequency >= 3 THEN 5
        END AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),
rfm_final AS (
    SELECT
        customer_unique_id,
        (r_score + f_score + m_score) / 3 AS avg_score,
        CASE 
            WHEN (r_score + f_score + m_score) / 3 >= 4 THEN 'Champion'
            WHEN (r_score + f_score + m_score) / 3 >= 3 THEN 'Loyal Customer'
            WHEN (r_score + f_score + m_score) / 3 >= 2 THEN 'At Risk'
            ELSE 'Lost'
        END AS customer_tier
    FROM rfm_scores
)
SELECT customer_tier, COUNT(*) AS num_customers
FROM rfm_final
GROUP BY customer_tier
ORDER BY num_customers DESC;

-- Finding: At Risk 47,917 (50%) | Loyal Customer 23,307 (24%) | Lost 23,293 (24%)
-- | Champion 903 (0.9%)
