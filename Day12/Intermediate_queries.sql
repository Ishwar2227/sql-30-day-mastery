-- I1. Build a running/cumulative revenue report.
-- Show order_date, daily_revenue, cumulative_revenue.
-- Use SUM() as both aggregate and window function.
SELECT order_date ,
	SUM(total_amount) AS daily_revenue,
	SUM(SUM(total_amount)) OVER (ORDER BY order_date) AS cumulative_revenue
FROM orders
GROUP BY order_date
ORDER BY order_date;


-- I2. Calculate month-over-month revenue growth.
-- Show month, revenue, prev_month_revenue, growth_pct.
-- Use LAG. Round growth_pct to 2 decimal places.
-- Handle the first month (prev will be NULL).
WITH monthly AS (
		SELECT DATE_TRUNC('month',order_date) AS month,
		SUM(total_amount) AS revenue
		FROM orders 
		GROUP BY DATE_TRUNC('month', order_date)
)
SELECT month , revenue,
		LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
		ROUND(
				(revenue - LAG(revenue) OVER (ORDER BY month))
				* 100.0 / LAG(revenue) OVER (ORDER BY month),2) AS growth_pct
		FROM monthly;


-- I3. Find the top spending customer per city.
-- Show city, customer_name, total_spent.
-- Use DENSE_RANK() OVER (PARTITION BY city).
WITH ranked AS (
		SELECT city, customer_name,
				SUM(total_amount) AS total_spent,
				DENSE_RANK() OVER (PARTITION BY city
					ORDER BY SUM(total_amount) DESC
		) AS city_rank 
		FROM customers c 
		JOIN orders o ON c.customer_id = o.customer_id
		GROUP BY city, customer_name
)
		
SELECT city, customer_name , total_spent
FROM ranked
WHERE city_rank = 1;


-- I4. Show for each customer: their name, total orders,
-- total spent, average order value, and whether
-- they are Repeat or One-time.
-- Show all customers including those with no orders
-- (use LEFT JOIN — show 0s not NULLs).
SELECT customer_name , COUNT(order_id) AS total_orders,
		COALESCE(SUM(total_amount),0) AS total_spent, 
		COALESCE(AVG(total_amount),0) AS avg_order_value,
		CASE 
			WHEN COUNT(order_id) > 1 THEN 'Repeat'
			ELSE 'One-time'
		END AS customer_type 
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY customer_amount;


-- I5. Find customers who placed orders in at least 2
-- different months. Show customer_name and active_months.
-- Hint: COUNT(DISTINCT DATE_TRUNC('month', order_date))
WITH monthly AS (
		SELECT customer_name ,
		COUNT(DISTINCT DATE_TRUNC('month',order_date)) AS active_months
		FROM customers c 
		JOIN orders o ON c.customer_id = o.customer_id
		GROUP BY customer_name 
)
SELECT customer_name, active_months
FROM monthly
WHERE active_months >= 2;