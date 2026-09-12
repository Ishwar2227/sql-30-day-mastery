-- B1. Show daily revenue — one row per order_date,
-- with total revenue for that day.
-- Order by date ascending.
SELECT order_date,
       SUM(total_amount) AS daily_revenue,
FROM orders
GROUP BY order_date
ORDER BY order_date;


-- B2. Show each customer's first order date.
-- Show customer_name and first_order_date.
-- Use MIN() and JOIN.
WITH first_order AS (
		SELECT customer_name,
			MIN(order_date) AS first_order_date
		FROM orders o
		JOIN customers c ON c.customer_id = o.customer_id
		GROUP BY customer_name
)
SELECT customer_name,first_order_date
FROM first_order;

-- B3. Classify customers as 'Repeat' or 'One-time'
-- based on whether they have more than 1 order.
-- Show customer_name and customer_type.
SELECT customer_name,
		COUNT(DISTINCT order_id) AS order_count,
		CASE WHEN COUNT(DISTINCT order_id) > 1
			THEN 'Repeat' ELSE 'One-time'
		END AS customer_type
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY customer_name;


-- B4. Show monthly revenue — one row per month.
-- Use DATE_TRUNC. Show month and monthly_revenue.
SELECT DATE_TRUNC('month', order_date) AS month,
       SUM(total_amount) AS monthly_revenue
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;


-- B5. Find customers whose first order was in January 2024.
-- Show customer_name and first_order_date.
WITH first_order AS (
    SELECT
        c.customer_name,
        MIN(o.order_date) AS first_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_name
)

SELECT customer_name,
       first_order_date
FROM first_order
WHERE first_order_date >= '2024-01-01'
  AND first_order_date < '2024-02-01';






