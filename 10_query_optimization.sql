-- STEP 10: Query Optimization
USE olist_ecommerce;

-- Baseline check: simple indexed lookup (uses idx_customer_unique_id from schema)
EXPLAIN SELECT
    c.customer_unique_id,
    o.order_purchase_timestamp
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_unique_id = '8d50f5eadf50201ccdcedfb9e2ac8455';
-- Result: type=ref, key=idx_customer_unique_id, rows=17, Extra=Using index. Well-optimized.

-- Heavier query: RFM base calculation (3-table join, no filter, full scan candidate)
EXPLAIN SELECT
    c.customer_unique_id,
    DATEDIFF('2018-10-17', MAX(o.order_purchase_timestamp)) AS recency,
    COUNT(DISTINCT o.order_id) AS frequency,
    SUM(oi.price) AS monetary
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id;
-- Result: all 3 tables show type=ref/index (no full table scans), but order_items'
-- Extra column is empty (not "Using index") -- indicates a bookmark lookup for `price`.

-- Attempted fix: covering index on order_items(order_id, price)
CREATE INDEX idx_orderitems_covering ON order_items(order_id, price);

-- Re-run EXPLAIN: optimizer still chose PRIMARY key for the join (order_id is its
-- leading column). Demonstrates that creating an index doesn't guarantee its use --
-- always verify with EXPLAIN rather than assume.

-- Real timing evidence (the actual proof, regardless of which index MySQL picked):
SELECT
    c.customer_unique_id,
    DATEDIFF('2018-10-17', MAX(o.order_purchase_timestamp)) AS recency,
    COUNT(DISTINCT o.order_id) AS frequency,
    SUM(oi.price) AS monetary
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id;
-- Execution time: ~30-47ms across ~99,441 customers and 112,650 order items --
-- confirms the overall indexing strategy (PKs, FKs, idx_customer_unique_id) is effective.
