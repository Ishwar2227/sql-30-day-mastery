-- NP1. Show each state's revenue, its percentage of total revenue,
-- and its rank. No double aggregation. No GROUP BY in outer query.

WITH state_rev AS(
	SELECT 
		state,
		ROUND(SUM(unit_price * quantity * (1 - discount_pct / 100.0)),2) AS state_revenue
	FROM fact_orders fo 
	JOIN fact_order_items fi ON fo.order_id = fi.order_id
	GROUP BY state
)
SELECT 
	state,
	state_revenue,
	ROUND(state_revenue * 100.0 / SUM(state_revenue) OVER(),2) AS pct_of_total_rev,
	RANK() OVER(
		ORDER BY state_revenue DESC
	) AS rank
FROM state_rev;


-- NP2. For each month in 2024, show how many customers were active
-- (placed at least one order) vs inactive (no order that month).
-- Use GENERATE_SERIES + CROSS JOIN + LEFT JOIN with two ON conditions.
-- Show month, active_count, inactive_count.

WITH all_months AS(
	SELECT GENERATE_SERIES(
	'2024-01-01'::DATE,
	'2024-12-01'::DATE,
	'1 month'::INTERVAL
	)::DATE AS month
),
all_customers AS(
	SELECT customer_id 
	FROM dim_customers
),
monthly_customers AS(
	SELECT 
		am.month,
		ac.customer_id 
	FROM all_months am
	CROSS JOIN all_customers ac
)
SELECT 
	mc.month,
	COUNT(DISTINCT fo.customer_id) AS active_count,
	COUNT(DISTINCT mc.customer_id) -  COUNT(DISTINCT fo.customer_id) AS inactive_count
FROM monthly_customers mc
LEFT JOIN fact_orders fo ON fo.customer_id = mc.customer_id
AND DATE_TRUNC('month',fo.order_date) = mc.month
GROUP BY mc.month
ORDER BY mc.month;


-- NP3. Find customers whose average order value is higher than
-- the average order value of all customers in their state.
-- Use a correlated subquery in WHERE.
-- Show customer_name, city, state, avg_order_value.

WITH order_totals AS(
	SELECT 
		fo.order_id,
		fo.customer_id,
		SUM(fi.unit_price * fi.quantity * (1 - fi.discount_pct / 100.0)) AS order_total
	FROM fact_orders fo 
	JOIN fact_order_items fi ON fo.order_id = fi.order_id
	GROUP BY fo.order_id, fo.customer_id
),
customer_aov AS(
	SELECT 
		c.customer_id , customer_name , city, state,
		AVG(order_total) AS avg_order_value
	FROM dim_customers c 
	JOIN order_totals ot ON c.customer_id = ot.customer_id
	GROUP BY c.customer_id , customer_name , city, state
)
SELECT 
	customer_name , city, state,
	ROUND(avg_order_value,2) AS avg_order_value
FROM customer_aov ca
WHERE ca.avg_order_value > (
	SELECT AVG(v.avg_order_value)
	FROM customer_aov v
	WHERE v.state = ca.state
)
ORDER BY ca.state, ca.avg_order_value DESC;


-- NP4. Fix your Day 25 Q2 query. Add the missing rank column.
-- Run it. Paste the output showing all states with revenue,
-- pct_of_total, and rank.

WITH state_cal AS(
	SELECT 
		state,
		ROUND(SUM(unit_price * quantity * (1 - discount_pct / 100)),2
		) AS revenue
	FROM fact_orders fo 
	JOIN fact_order_items fi ON fo.order_id = fi.order_id
	GROUP BY state
)
SELECT 
	state,revenue,
	ROUND(revenue * 100.0 
	/ SUM(revenue) OVER(),2) AS pct_of_total,
	RANK() OVER( ORDER BY revenue DESC) AS rank
FROM state_cal 
ORDER BY revenue DESC;
'''
"Maharashtra"	1428525.00	53.14	1
"Delhi"	648000.00	24.11	2
"Karnataka"	241500.00	8.98	3
"Telangana"	234600.00	8.73	4
"Rajasthan"	67500.00	2.51	5
"Kerala"	30600.00	1.14	6
"Tamil Nadu"	19500.00	0.73	7
"Gujarat"	18000.00	0.67	8
'''

-- NP5. Fix your Day 25 Q3 query. Change cost_price to cost.
-- Run it. Paste the top 5 products by profit margin.

WITH product_stats AS (
    SELECT
        dp.product_id,dp.product_name,
        dp.category,
        SUM(fi.quantity) AS total_units_sold,
        SUM(fi.unit_price * fi.quantity * (1 - fi.discount_pct / 100.0)
        ) AS total_revenue,
        SUM(
            (
                fi.unit_price * fi.quantity
                * (1 - fi.discount_pct / 100.0)
            ) - (dp.cost * fi.quantity)
        ) AS total_profit
        
    FROM fact_order_items fi
    JOIN dim_products dp ON fi.product_id = dp.product_id
    GROUP BY
        dp.product_id, dp.product_name, dp.category
),
ranked_products AS (
    SELECT
        *,
        ROUND( total_profit * 100.0 / NULLIF(total_revenue, 0),
            2) AS profit_margin_pct,
        RANK() OVER (
            PARTITION BY category
            ORDER BY total_revenue DESC
        ) AS revenue_rank_in_category
    FROM product_stats
)
SELECT
    product_id,product_name,
    category,profit_margin_pct,
    revenue_rank_in_category
FROM ranked_products
ORDER BY profit_margin_pct DESC
LIMIT 5;
