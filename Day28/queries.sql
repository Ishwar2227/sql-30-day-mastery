-- Find the 3rd highest total_amount in fact_orders. No LIMIT/OFFSET —
-- use a subquery.

with total AS(
	SELECT 
		fo.order_id,
		SUM(fi.unit_price * fi.quantity * (1 - fi.discount_pct / 100.0)) 
		AS total_amount
	FROM fact_orders fo 
	JOIN fact_order_items fi ON fo.order_id = fi.order_id
	GROUP BY fo.order_id
)
SELECT 	
	MAX(total_amount) AS third_highest
FROM total 
WHERE total_amount <(
	SELECT MAX(total_amount)
	FROM total 
	WHERE total_amount <(
		SELECT MAX(total_amount)
		FROM total
	)
);


-- Show each customer's total revenue and their rank, using DENSE_RANK,
-- including customers with zero orders (rank should show NULL for them).

WITH customer_rev AS(
	SELECT 
		dc.customer_id,
		SUM(fi.unit_price * fi.quantity * (1 - fi.discount_pct / 100.0)
		) AS total_revenue
	FROM dim_customers dc
	LEFT JOIN fact_orders fo ON dc.customer_id = fo.customer_id
	LEFT JOIN fact_order_items fi ON fo.order_id = fi.order_id
	GROUP BY dc.customer_id
)
SELECT 
	customer_id,
	CASE 
		WHEN total_revenue IS NULL THEN NULL
		ELSE DENSE_RANK() OVER(
			ORDER BY total_revenue DESC)
	END AS revenue_rank
FROM customer_rev
ORDER BY customer_id;


-- Find duplicate rows in fact_order_items (same order_id + product_id
-- appearing more than once).

SELECT 
	order_id, product_id,
	COUNT(*) AS occurrence_count
FROM fact_order_items
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;


-- 1. Using the consecutive-months technique from Day 21, find products
-- that sold in at least 2 consecutive months.

WITH product_details AS(
	SELECT 
		dp.product_name,
		DATE_TRUNC('month',order_date) AS month,
		COUNT(fo.order_id) AS order_count,
		CASE
            WHEN COUNT(fo.order_id) > 0 THEN 1
            ELSE 0
        END AS flags
		FROM dim_products dp

    JOIN fact_order_items foi
        ON dp.product_id = foi.product_id

    JOIN fact_orders fo
        ON foi.order_id = fo.order_id

    GROUP BY
        dp.product_name,
        DATE_TRUNC('month', fo.order_date)
),
rolling AS (
    SELECT
        product_name,
        month,
        SUM(flags) OVER (
            PARTITION BY product_name
            ORDER BY month
            ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
        ) AS consecutive_count
    FROM product_details
)

SELECT
    product_name,
    month
FROM rolling
WHERE consecutive_count = 2;


-- Using the retention technique from Day 23, show monthly new vs
-- returning customers for 2024 — including months with zero activity
-- (use GENERATE_SERIES).

WITH all_months AS(
	SELECT 
		GENERATE_SERIES(
			'2024-01-01'::DATE,
			'2024-12-01'::DATE,
			'1 month'::INTERVAL
		)::DATE AS month
),
user_period AS(
	SELECT 
		c.customer_id,
		DATE_TRUNC('month', fo.order_date)::DATE AS month
	FROM dim_customers c
	JOIN fact_orders fo ON c.customer_id = fo.customer_id
	WHERE fo.order_date >= '2024-01-01'
		AND fo.order_date < '2025-01-01'
	GROUP BY c.customer_id , DATE_TRUNC('month', fo.order_date)::DATE 
),
first_seen AS(
	SELECT 
		customer_id,
		MIN(month) AS first_month
	FROM user_period
	GROUP BY customer_id
),
classification AS(
	SELECT 
		am.month,
		fs.customer_id, fs.first_month,
		CASE 	
			WHEN fs.first_month = am.month
				THEN 'new'
			WHEN up.customer_id IS NOT NULL
				THEN 'returning'
		END AS customer_type
	FROM all_months am
	CROSS JOIN first_seen fs 
	LEFT JOIN user_period up 
		ON fs.customer_id = up.customer_id
		AND am.month = up.month
)
SELECT 
	month,
	COUNT(*) FILTER(
		WHERE customer_type = 'new'
	)AS new_customers,

	COUNT(*) FILTER	(
		WHERE customer_type = 'returning'
	)AS returning_customers
FROM classification
GROUP BY month
ORDER BY month;


-- 1. Using the rolling average technique from Day 22, show each
-- customer's 3-month rolling average revenue, only for customers
-- active in 3+ distinct months.

WITH customer_stats AS(
	SELECT 
		dp.customer_id,
		DATE_TRUNC('month',order_date) AS month,
		ROUND(SUM(unit_price * quantity * (1-discount_pct / 100.0)),2
		) AS monthly_revenue
	FROM dim_customers dp 
	JOIN fact_orders fo ON dp.customer_id = fo.customer_id
	JOIN fact_order_items fi ON fo.order_id = fi.order_id
	GROUP BY dp.customer_id, DATE_TRUNC('month',order_date)
),
active_customers AS(
	SELECT 
		customer_id
	FROM customer_stats 
	GROUP BY customer_id
	HAVING COUNT(DISTINCT month) >= 3
)
SELECT
	cs.customer_id,
	cs.month,
	cs.monthly_revenue,

	ROUND(AVG(cs.monthly_revenue) OVER(
		PARTITION BY cs.customer_id
		ORDER BY cs.month
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
	),2)AS rolling_avg
FROM customer_stats cs
JOIN active_customers ac ON cs.customer_id = ac.customer_id
ORDER BY cs.customer_id, cs.month;



-- ## Block 3 — One Harder Problem (1 question)
-- Build a simple churn flag report: for each customer, show their
-- last order date and whether they're "High risk" (no order in 60+
-- days relative to the dataset's most recent order) or "Low risk".
-- Then show what percentage of customers are High risk.

WITH customer_last_order AS (
    SELECT 
        customer_id,
        MAX(order_date) AS last_order_date
    FROM fact_orders
    GROUP BY customer_id
),
dataset_latest_order AS (
    SELECT 
        MAX(order_date) AS latest_order_date
    FROM fact_orders
),
risk_report AS (
    SELECT 
        clo.customer_id,
        clo.last_order_date,

        CASE 
            WHEN dlo.latest_order_date - clo.last_order_date >= 60
                THEN 'High risk'
            ELSE 'Low risk'
        END AS risk_level

    FROM customer_last_order clo
    CROSS JOIN dataset_latest_order dlo
)
SELECT
    customer_id,
    last_order_date,
    risk_level,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE risk_level = 'High risk')
        OVER ()
        / COUNT(*) OVER (),
        2
    ) AS pct_high_risk
FROM risk_report
ORDER BY customer_id;
