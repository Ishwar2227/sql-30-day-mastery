-- B1. Build a pivot table showing total revenue per month
-- broken down by order status.
-- Columns: month, delivered_rev, cancelled_rev,
-- processing_rev, shipped_rev.
SELECT 
	DATE_TRUNC('month',order_date) AS month,
	SUM(CASE WHEN status = 'delivered' THEN total_amount ELSE 0 END) AS delivered_rev,
	SUM(CASE WHEN status = 'cancelled' THEN total_amount ELSE 0 END) AS cancelled_rev,
	SUM(CASE WHEN status = 'processing' THEN total_amount ELSE 0 END) AS processing_rev,
	SUM(CASE WHEN status = 'shipped' THEN total_amount ELSE 0 END) AS shipped_rev
FROM orders 
GROUP BY DATE_TRUNC('month',order_date);


-- B2. Show each order's total_amount, its PERCENT_RANK,
-- and its CUME_DIST across all orders.
-- Show order_id, total_amount, percent_rank, cume_dist.
SELECT 
	order_id,total_amount,
	PERCENT_RANK() OVER(ORDER BY total_amount ) AS percent_rank,
	CUME_DIST() OVER(ORDER BY total_amount) AS cume_dist
FROM orders ;


-- B3. For each customer show their first order amount
-- and last order amount using FIRST_VALUE and LAST_VALUE.
-- Show customer_name, first_order_amt, last_order_amt.
SELECT 
	customer_name ,
	FIRST_VALUE(total_amount) OVER(
		PARTITION BY customer_name 
		ORDER BY order_date
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
	) AS first_order_amt,
	LAST_VALUE(total_amount) OVER(
		PARTITION BY customer_name
		ORDER BY order_date
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
	) AS last_order_amt
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id;


-- B4. Calculate ARPU (Average Revenue Per User).
-- Show a single value: arpu.
SELECT 
	SUM(total_amount) / COUNT(DISTINCT customer_id) AS arpu 
FROM orders;


-- B5. Show each order and which percentile it falls in
-- (use NTILE(100) to assign a percentile rank).
-- Show order_id, total_amount, percentile.
SELECT 
		order_id , total_amount,
		NTILE(100) OVER(ORDER BY total_amount) AS percentile
	FROM orders;


-- ## 🟡 Intermediate
-- I1. Build a city revenue pivot showing total revenue per city
-- broken down by order status.
-- Columns: city, delivered, cancelled, processing, shipped.
SELECT 
	city,
	SUM(CASE WHEN status = 'delivered' THEN total_amount ELSE 0 END) AS delivered,
	SUM(CASE WHEN status = 'cancelled' THEN total_amount ELSE 0 END) AS cancelled,
	SUM(CASE WHEN status = 'processing' THEN total_amount ELSE 0 END) AS processing,
	SUM(CASE WHEN status = 'shipped' THEN total_amount ELSE 0 END) AS shipped
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY city;


-- I2. Find customers in the top 20% of spenders
-- using PERCENT_RANK or CUME_DIST.
-- Show customer_name, total_spent, spend_percentile.
WITH ranked AS(
	SELECT 
		customer_name , SUM(total_amount) AS total_spent,
		PERCENT_RANK() OVER(ORDER BY SUM(total_amount)) AS spend_percentile
	FROM customers c 
	JOIN orders o ON c.customer_id = o.customer_id
	GROUP BY customer_name
) 
SELECT 
	customer_name , 
	total_spent,spend_percentile
FROM ranked 
WHERE spend_percentile >= 0.80
ORDER BY total_spent DESC;


-- I3. For each customer show their first order,
-- second order (using NTH_VALUE), and latest order amounts.
-- Show customer_name, first_order, second_order, latest_order.
SELECT 
	customer_name ,
	FIRST_VALUE(total_amount) OVER(PARTITION BY customer_name 
		ORDER BY order_date 
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
	) AS first_order,
	NTH_VALUE(total_amount,2) OVER(PARTITION BY customer_name 
		ORDER BY order_date DESC 
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
	) AS second_order,
	LAST_VALUE(total_amount) OVER(PARTITION BY customer_name
		ORDER BY order_date 
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING 
	) AS latest_order 
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id ;


-- I4. Calculate these business KPIs in one query:
-- - total_revenue
-- - total_customers
-- - total_orders
-- - arpu (revenue per customer)
-- - avg_order_value
-- - repeat_purchase_rate (% with more than 1 order)
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id
)
SELECT SUM(total_amount) AS total_revenue,
	COUNT(DISTINCT customer_id) AS total_customers ,
	COUNT(order_id) AS total_orders,
	SUM(total_amount) / COUNT(DISTINCT customer_id) AS arpu,
	AVG(total_amount) AS avg_order_value,
	(
		SELECT COUNT(CASE WHEN order_count > 1 THEN 1 END) * 100.0
		/COUNT(*)
		FROM customer_orders 
	) AS repeat_purchase_rate
FROM orders;


-- I5. Show monthly revenue with:
-- - monthly_revenue
-- - cumulative_revenue (running total)
-- - pct_of_annual (this month as % of total annual)
-- - mom_growth (month over month growth %)
-- All in one query using CTEs and window functions.
WITH revenue AS (
	SELECT
		DATE_TRUNC('month',order_date) AS month,
		SUM(total_amount) AS monthly_revenue
	FROM orders 
	GROUP BY DATE_TRUNC('month',order_date)
) 
SELECT 
	month,monthly_revenue,
	SUM(monthly_revenue) OVER(ORDER BY month) AS cumulative_revenue,
	ROUND(
		monthly_revenue * 100.0 / SUM(monthly_revenue) OVER(),2
		) AS pct_of_annual,
		
	ROUND(
		(
			monthly_revenue - LAG(monthly_revenue) OVER(ORDER BY month)
		) *100.0
		/ LAG(monthly_revenue) OVER(ORDER BY month),2) AS mom_growth
FROM revenue
ORDER BY month;


-- ## 🔴 Challenging
-- C1. Build a revenue concentration analysis:
-- Divide customers into 5 quintiles by spend.
-- Show what percentage of total revenue comes
-- from each quintile.
-- Show quintile, quintile_revenue, pct_of_total.
-- This is the SQL version of the 80/20 rule analysis.
WITH customer_report AS(
	SELECT 
		customer_name ,
		SUM(total_amount) AS total_spent
	FROM orders o
	JOIN customers c ON c.customer_id = o.customer_id 
	GROUP BY customer_name
),
ranked AS (
	SELECT 
		customer_name , total_spent,
		NTILE(5) OVER(ORDER BY total_spent) AS quintile
	FROM customer_report
)
SELECT quintile,
	SUM(total_spent) AS quintile_revenue,
	ROUND(
	SUM(total_spent) * 100.0 
	/ SUM(SUM(total_spent)) OVER(),2) AS pct_of_total
FROM ranked
GROUP BY quintile
ORDER BY quintile;
