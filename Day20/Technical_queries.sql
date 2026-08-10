-- Q4. [Business Problem]
-- Using the ecommerce dataset, your manager asks:
-- "Which customers have increased their spending each month
-- compared to the previous month for at least 2 consecutive months?"
-- Show customer_name and the months where this happened.

WITH monthly_spend AS (
    SELECT dc.customer_name,
        DATE_TRUNC('month', fo.order_date) AS month,
        ROUND(SUM(foi.unit_price * foi.quantity *
              (1 - foi.discount_pct/100.0)), 2) AS monthly_revenue
    FROM dim_customers dc
    JOIN fact_orders fo ON dc.customer_id = fo.customer_id
    JOIN fact_order_items foi ON fo.order_id = foi.order_id
    GROUP BY dc.customer_id, dc.customer_name,
             DATE_TRUNC('month', fo.order_date)
),
with_prev AS (
    SELECT customer_name, month, monthly_revenue,
        LAG(monthly_revenue) OVER (
            PARTITION BY customer_name ORDER BY month
        ) AS prev_revenue,
        LAG(month) OVER (
            PARTITION BY customer_name ORDER BY month
        ) AS prev_month
    FROM monthly_spend
),
increases AS (
    SELECT customer_name, month,
        CASE WHEN monthly_revenue > prev_revenue
             AND month = prev_month + INTERVAL '1 month'
             THEN 1 ELSE 0 END AS is_increase
    FROM with_prev
),
consecutive AS (
    SELECT customer_name, month,
        SUM(is_increase) OVER (
            PARTITION BY customer_name
            ORDER BY month
            ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
        ) AS consecutive_increases
    FROM increases
)
SELECT DISTINCT customer_name, month
FROM consecutive
WHERE consecutive_increases = 2;


-- Q5. [Complex Aggregation]aaaaaaa
-- Build a product performance matrix showing:

-- - product_name
-- - total_units_sold
-- - total_revenue (with discount formula)
-- - total_profit
-- - profit_margin_pct
-- - revenue_rank (rank by revenue within category)
-- - is_top_performer (TRUE if profit_margin_pct > category average)

WITH product_per AS (
	SELECT 
		dp.product_name , SUM(fi.quantity) AS total_units_sold,
		ROUND(SUM(fi.unit_price * fi.quantity * (1-fi.discount_pct/100.0)),2) AS total_revenue,
		ROUND(
	        SUM((fi.unit_price - dp.cost) * fi.quantity * (1 - fi.discount_pct / 100.0)),
	        2) AS total_profit,
	  ROUND(
	        (SUM((fi.unit_price - dp.cost) * fi.quantity * (1 - fi.discount_pct / 100.0))
	            /SUM(fi.unit_price * fi.quantity * (1 - fi.discount_pct / 100.0))
	        ) * 100,2) AS profit_margin_pct,
	  dp.category
		FROM dim_products dp 
		JOIN fact_order_items fi ON dp.product_id = fi.product_id
		GROUP BY dp.product_name,dp.category
)
SELECT product_name, total_units_sold, total_revenue,
    total_profit, profit_margin_pct, category,
    RANK() OVER (PARTITION BY category
                 ORDER BY total_revenue DESC) AS revenue_rank,
    profit_margin_pct > AVG(profit_margin_pct)
        OVER (PARTITION BY category) AS is_top_performer
FROM product_per;


-- Q6. [Time Series]
-- For each month in 2024, show:

-- - month
-- - new_customers (first order in that month)
-- - returning_customers (ordered before and again in this month)
-- - churned_customers (ordered before, not in this month)
-- Use CTEs. This is a classic retention analysis.

WITH all_orders AS (
    SELECT customer_id,
        DATE_TRUNC('month', order_date) AS month
    FROM fact_orders
    WHERE order_date >= '2024-01-01'
    GROUP BY customer_id, DATE_TRUNC('month', order_date)
),
first_orders AS (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM fact_orders GROUP BY customer_id
),
months AS (
    SELECT DISTINCT month FROM all_orders
),
classification AS (
    SELECT m.month, ao.customer_id,
        fo.first_order_date,
        CASE
            WHEN DATE_TRUNC('month', fo.first_order_date) = m.month
                THEN 'new'
            WHEN ao.customer_id IS NOT NULL
                THEN 'returning'
            ELSE 'churned'
        END AS customer_type
    FROM months m
    CROSS JOIN first_orders fo
    LEFT JOIN all_orders ao
        ON fo.customer_id = ao.customer_id AND ao.month = m.month
    WHERE DATE_TRUNC('month', fo.first_order_date) <= m.month
)
SELECT month,
    COUNT(*) FILTER (WHERE customer_type = 'new') AS new_customers,
    COUNT(*) FILTER (WHERE customer_type = 'returning') AS returning_customers,
    COUNT(*) FILTER (WHERE customer_type = 'churned') AS churned_customers
FROM classification
GROUP BY month ORDER BY month;
