-- I1. Build the full RFM feature table:
-- customer_id, recency_days, frequency, monetary,
-- recency_score (NTILE 1-4, lower days = higher score),
-- frequency_score (NTILE 1-4),
-- monetary_score (NTILE 1-4),
-- rfm_total_score (sum of three scores).

WITH customer_info AS(
	SELECT 
		customer_id,
		MAX(order_date) AS latest_order_date,
		COUNT(DISTINCT fo.order_id) AS frequency,
		ROUND(SUM(unit_price * quantity * (1 - discount_pct / 100.0)),2) AS monetary
	FROM fact_orders fo
	JOIN fact_order_items fi ON fo.order_id = fi.order_id
	GROUP BY customer_id
),
scores AS(
	SELECT 
		customer_id , 
		(SELECT MAX(order_date) FROM fact_orders) - latest_order_date AS recency_days,
		frequency, monetary
	FROM customer_info
)
SELECT 
	customer_id , recency_days, frequency, monetary,
	5 - NTILE(4) OVER(ORDER BY recency_days) AS recency_score,
	NTILE(4) OVER(ORDER BY frequency) AS frequency_score,
	NTILE(4) OVER(ORDER BY monetary) AS monetary_score,
	(
		5 - NTILE(4) OVER(ORDER BY recency_days) +
		NTILE(4) OVER(ORDER BY frequency) +
		NTILE(4) OVER(ORDER BY monetary) 
	)AS rfm_total_score
FROM scores
ORDER BY customer_id;


-- I2. Build lag features for each customer showing their
-- monthly revenue for each active month plus:
-- prev_1m_revenue, prev_2m_revenue, prev_3m_revenue,
-- mom_growth_rate (current vs prev 1m, as ratio).

WITH customer_info AS(
	SELECT 
		customer_id ,
		DATE_TRUNC('month',order_date) AS month,
		ROUND(SUM(unit_price * quantity * (1 - discount_pct / 100.0)),2) AS monthly_revenue
	FROM fact_orders fo
	JOIN fact_order_items fi ON fo.order_id = fi.order_id
	GROUP BY customer_id , DATE_TRUNC('month',order_date)
)
SELECT 
	customer_id , month, monthly_revenue,
	LAG(monthly_revenue,1) OVER(PARTITION BY customer_id ORDER BY month) AS prev_1m_revenue,
	LAG(monthly_revenue,2) OVER(PARTITION BY customer_id ORDER BY month) AS prev_2m_revenue,
	LAG(monthly_revenue,3) OVER(PARTITION BY customer_id ORDER BY month) AS prev_3m_revenue,
	monthly_revenue / NULLIF(LAG(monthly_revenue, 1)
	    OVER (PARTITION BY customer_id ORDER BY month), 0)
        AS revenue_growth_ratio
FROM customer_info;


-- I3. Create a customer diversity feature:
-- customer_id,
-- category_count (distinct categories bought),
-- product_count (distinct products bought),
-- avg_discount_received (average discount_pct across all purchases),
-- cancelled_order_pct (cancelled orders / total orders).


WITH cust_info AS(
	SELECT 
		customer_id,
		COUNT(DISTINCT category) AS category_count,
		COUNT(DISTINCT dp.product_id) AS product_count,
		ROUND(AVG(fi.discount_pct),2) AS avg_discount_received,
		COUNT(DISTINCT CASE WHEN fo.status = 'cancelled' THEN fo.order_id END) 
		AS cancelled_orders,
		COUNT(DISTINCT fo.order_id) AS total_orders
	FROM fact_orders fo 
	JOIN fact_order_items fi ON fo.order_id = fi.order_id
	JOIN dim_products dp ON fi.product_id = dp.product_id
	GROUP BY customer_id
)
SELECT 
	customer_id,category_count, product_count, avg_discount_received,
	ROUND((cancelled_orders * 100.0) / NULLIF(total_orders,0),2) 
	AS cancelled_order_pct
FROM cust_info;


-- I4. Build churn labels:
-- A customer is "churned" if their last order was more than
-- 60 days before the most recent order in the dataset.
-- Show customer_id, last_order_date, days_inactive, is_churned (1/0).
-- This is the target variable for a churn model.

WITH cust_info AS(
	SELECT 
		customer_id, 
		MAX(order_date) AS last_order_date,
		(SELECT MAX(order_date) FROM fact_orders) - MAX(order_date) AS days_inactive
	FROM fact_orders
	GROUP BY customer_id
)
SELECT 
	customer_id, last_order_date, days_inactive,
	CASE WHEN days_inactive > 60 THEN 1 ELSE 0 END AS is_churned
FROM cust_info;


-- I5. Combine all features into one master feature table:
-- Use CTEs to compute each feature group separately,
-- then JOIN them all on customer_id.
-- Show: customer_id, recency_days, frequency, monetary,
-- category_diversity, cancelled_pct, is_churned.
-- This is your ML-ready dataset.

WITH rfm_features AS (
    SELECT
        fo.customer_id,
        (SELECT MAX(order_date) FROM fact_orders)
        - MAX(fo.order_date) AS recency_days,
				COUNT(DISTINCT fo.order_id) AS frequency,
        ROUND(SUM(fi.unit_price * fi.quantity* (1 - fi.discount_pct / 100.0)
            ), 2) AS monetary
    FROM fact_orders fo
    JOIN fact_order_items fi ON fo.order_id = fi.order_id
    GROUP BY fo.customer_id
),
diversity_features AS (
    SELECT
        fo.customer_id,
        COUNT(DISTINCT dp.category) AS category_diversity,
        ROUND(COUNT(DISTINCT CASE
                WHEN fo.status = 'cancelled'
                THEN fo.order_id
            END) * 100.0
            / NULLIF(COUNT(DISTINCT fo.order_id), 0),
            2) AS cancelled_pct
    FROM fact_orders fo
    JOIN fact_order_items fi ON fo.order_id = fi.order_id
    JOIN dim_products dp ON fi.product_id = dp.product_id
    GROUP BY fo.customer_id
),

churn_labels AS (
    SELECT
        customer_id,
        CASE
            WHEN(SELECT MAX(order_date) FROM fact_orders)
             - MAX(order_date) > 60
            THEN 1 ELSE 0 END AS is_churned
    FROM fact_orders
    GROUP BY customer_id
)
SELECT
    r.customer_id,
    r.recency_days,
    r.frequency,
    r.monetary,
    d.category_diversity,
    d.cancelled_pct,
    c.is_churned

FROM rfm_features r
JOIN diversity_features d ON r.customer_id = d.customer_id
JOIN churn_labels c ON r.customer_id = c.customer_id
ORDER BY r.customer_id;





