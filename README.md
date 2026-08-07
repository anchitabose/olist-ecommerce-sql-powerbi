# Olist E-Commerce SQL + Power BI Analysis

An end-to-end analytics project analyzing ~99,000 orders from the Brazilian e-commerce marketplace Olist — a hand-built MySQL relational database powering a single-page Power BI dashboard. Covers schema design, data quality auditing, advanced SQL window functions, customer segmentation (RFM), retention/cohort analysis, query optimization, and dashboard visualization. Extended with a Python (Jupyter/pandas) layer for RFM validation and cohort retention visualization.

## Dataset

Source: Brazilian E-Commerce Public Dataset by Olist (Kaggle)

9 relational tables, ~1.5M total rows, covering orders, customers, products, sellers, payments, reviews, and geolocation data from 2016–2018.

| Table | Rows | Purpose |
|---|---|---|
| customers | 99,441 | Customer identity and location |
| orders | 99,441 | Order lifecycle and timestamps |
| order_items | 112,650 | Line-item level pricing per order |
| order_payments | 103,886 | Payment method and installments |
| order_reviews | 99,223 | Customer review scores and text |
| products | 32,951 | Product attributes |
| sellers | 3,095 | Seller identity and location |
| product_category_translation | 71 | Portuguese → English category names |
| geolocation | 1,000,163 | Zip-code-level lat/long lookup |

## Schema Design

A star-schema-style relational model was hand-built (not auto-imported) with explicit primary and foreign keys across all 9 tables. Key decisions:

- `order_items` uses a composite primary key (order_id, order_item_id), since a single order can contain multiple line items.
- `order_reviews` uses a composite key (review_id, order_id) to accommodate rare duplicate review IDs across different orders in the raw data.
- `geolocation` has no primary key — it's a crowd-sourced lookup table with many repeated, slightly inconsistent zip-code entries, so it's treated as reference data rather than an entity table.

## Data Quality Findings

- 2,965 orders (~3%) have no delivered_customer_date, aligning almost exactly with non-delivered order statuses — a business-status pattern, not a data defect.
- `customer_id` is order-scoped, not person-scoped — a critical finding. Each order generates a new customer_id, while `customer_unique_id` identifies the real person. The top repeat customer placed 17 orders under 17 different customer_id values. All customer-level analysis (retention, RFM) correctly groups by customer_unique_id.
- 610 products (1.9%) have no assigned category — excluded from category-level analysis, retained in overall revenue figures.
- 3 orders have line items but no matching payment record — likely a data extraction artifact.

## Key SQL Analyses & Findings

**1. Revenue by Category & Month**
Health & Beauty and Watches/Gifts are the top two revenue categories. Monthly revenue climbed steadily through 2017, peaking in November 2017 — consistent with Black Friday seasonality.

**2. Time Between Purchases (Self-Join & LAG)**
Built two approaches: a self-join comparing every order pair per customer, and a LAG() window function isolating consecutive orders. Average gap between repeat purchases: ~78 days.

**3. Top Products per Category (Window Functions)**
DENSE_RANK() partitioned by category surfaces the top 5 best-selling products within each category in a single query.

**4. Cumulative Revenue (Running Total)**
SUM() OVER (ORDER BY month) tracks cumulative revenue growth for trend visualization.

**5. Cohort Retention Analysis**
Using MIN() as a window function and TIMESTAMPDIFF(), customers were grouped into monthly acquisition cohorts. Retention is extremely low: of 764 customers acquired in January 2017, only 2 (0.3%) returned the following month — consistent across nearly every cohort.

**6. RFM Customer Segmentation**
A 4-layer CTE pipeline scored customers on Recency, Frequency, and Monetary value. Since ~97% of customers share a Frequency of 1, NTILE() produced arbitrary tie-splitting — replaced with a business-rule CASE statement instead.

| Tier | Customers | % |
|---|---|---|
| At Risk | 47,917 | 50% |
| Loyal Customer | 23,307 | 24% |
| Lost | 23,293 | 24% |
| Champion | 903 | 0.9% |

**7. Gap Detection (Recursive CTE)**
A recursive CTE generated a complete month-by-month calendar, LEFT JOINed against actual orders to auto-detect zero-order months: November 2016 (pre-launch phase) and November 2018 (data extraction cutoff, not a real gap).

**8. Reusable Tools: View & Stored Procedure**
- `seller_performance` view: always-current seller revenue, order count, and average review score.
- `top_sellers_by_date(start_date, end_date)` stored procedure: returns top 10 sellers by revenue for any custom date range.

**9. Query Optimization**
The RFM query executes in ~30–47ms across ~99,441 customers, backed by indexes on customer_unique_id and foreign keys. A covering index test on order_items(order_id, price) showed MySQL's optimizer still preferred the existing PRIMARY key — a reminder that adding an index doesn't guarantee its use; verifying with EXPLAIN is essential.

## Python Extension: RFM Validation & Cohort Retention Analysis

To extend the SQL analysis, a Jupyter Notebook was built connecting directly to the live MySQL database via SQLAlchemy, using Python to validate and visualize findings that were harder to surface in SQL alone.

**Connection:** `pandas` + `SQLAlchemy` + `pymysql`, read-only queries against the existing schema — no changes made to the underlying database or the Power BI dashboard's data source.

**1. RFM Scoring Correction**

Re-examining the original SQL RFM query's frequency-scoring logic surfaced a flaw: the CASE statement compressed multiple purchase-frequency levels (2, 3, 4, 5+ orders) into just two score values (3 or 5), rather than a proper 5-level scale like Recency and Monetary used. This inflated the Champion segment by scoring moderately frequent buyers (as few as 3 orders) the same as highly frequent ones.

The scoring logic was corrected to use full 5-level granularity for Frequency, matching the treatment of the other two dimensions:

| Version | Champions | At Risk | Loyal Customer | Lost |
|---|---|---|---|---|
| Original (SQL) | 903 (0.9%) | 47,917 | 23,307 | 23,293 |
| Corrected (Python) | 405 (0.4%) | 48,324 | 23,341 | 23,350 |

The correction reduced the Champion segment by ~55%, producing a more conservative and accurate high-value customer count — a materially different number for any retention-targeting or budget decision built on top of it.

**2. Cohort Retention Heatmap**

Building on the SQL cohort analysis, a full month-by-month retention heatmap was generated in Python (`matplotlib`/`seaborn`), tracking the percentage of each acquisition cohort still purchasing in subsequent months.

Cohorts with fewer than 50 customers (e.g., a single-customer cohort from December 2016) were filtered out before charting — small cohorts produced statistically meaningless swings (a lone customer reordering shows as "100% retention"), which would otherwise distort the visual. The filtered heatmap confirms the SQL finding at a more granular level: retention drops from 100% to under 1% almost immediately after a customer's first purchase, across nearly every cohort.

**Tools & Skills Demonstrated (Python)**

- Data pipeline: MySQL → pandas via SQLAlchemy (read-only)
- Data validation: identifying and correcting a scoring logic flaw in existing SQL output
- `groupby().agg()` aggregation logic (Recency/Frequency/Monetary calculation)
- Cohort construction: `.dt.to_period()`, pivot tables, retention-rate calculation
- Data quality filtering: minimum sample-size thresholding to avoid misleading small-n results
- Visualization: `seaborn` heatmaps with adjusted color scaling for skewed data

## Power BI Dashboard

A single-page dashboard connects live to the MySQL database (including two custom SQL-sourced tables for RFM and cohort data) to visualize the analysis findings above.

**Layout:**
- Hero KPI row — Total Revenue (₹13.59M), Total Orders (99K), Total Customers (96K), Avg Order Value (₹136.68)
- Monthly Revenue Trend — line chart showing 2016–2018 growth and the November 2017 Black Friday peak
- Top 8 Revenue-Generating Categories — horizontal bar chart
- Customer Segments (RFM) — donut chart showing the At Risk / Loyal / Lost / Champion split
- Customer Retention Curve — log-scale line chart visualizing the steep month-0-to-month-1 drop-off
  
## Tools & Skills Demonstrated

- Relational schema design (composite keys, foreign keys)
- Data cleaning and quality auditing
- Joins: inner, left, self-joins
- Window functions: RANK(), DENSE_RANK(), LAG(), MIN() OVER(), SUM() OVER(), NTILE()
- Multi-layer CTEs and recursive CTEs
- CASE statements for business-rule logic
- Views and stored procedures
- Query optimization with EXPLAIN and indexing
- Python: pandas, SQLAlchemy, matplotlib/seaborn, data validation and cohort analysis
- Power BI: live MySQL connection, custom SQL data sources, DAX measures, single-page dashboard design
- MySQL Workbench: schema design, LOAD DATA INFILE, connection/performance troubleshooting

## Repository Structure

```
├── schema/
│   └── create_tables.sql
├── data_loading/
│   └── load_data.sql
├── analysis/
│   ├── 01_data_cleaning.sql
│   ├── 02_revenue_analysis.sql
│   ├── 03_self_join_lag.sql
│   ├── 04_top_products_rank.sql
│   ├── 05_running_total.sql
│   ├── 06_cohort_retention.sql
│   ├── 07_rfm_segmentation.sql
│   ├── 08_gap_detection.sql
│   ├── 09_view_procedure.sql
│   └── 10_query_optimization.sql
├── python/
│   ├── olist_rfm_cohort_analysis.ipynb
│   ├── rfm_corrected.csv
│   └── cohort_retention.csv
├── dashboard/
│   ├── olist_dashboard.pbix
│   └── dashboard_screenshot.png
└── README.md
```

## Author

Anchita | Aspiring Data Analyst | [LinkedIn](https://www.linkedin.com/in/anchita-bose-46059b246/)
## Author

Anchita | Aspiring Data Analyst | [LinkedIn](https://www.linkedin.com/in/anchita-bose-46059b246/)
