-- W1. [Flipkart-style] Find all customers who placed more than
-- one order in the same month.
-- Show customer_name, month, order_count.


WITH monthly AS (
	SELECT customer_name , 
	DATE_TRUNC('month',order_date) AS month,
	COUNT(*) AS order_count
	FROM orders o 
	JOIN customers c ON c.customer_id = o.customer_id 
	GROUP BY customer_name , DATE_TRUNC('month',order_date) 
)
SELECT customer_name , month , order_count 
FROM monthly 
WHERE order_count > 1 ;


-- W2. [Amazon-style] Find the second most expensive order.
-- Show order_id and total_amount.
-- Solve it two ways: once with LIMIT/OFFSET,
-- once with a subquery. Which is better and why?


--LIMIT/OFFSET
SELECT
    order_id,
    total_amount
FROM orders
ORDER BY total_amount DESC
LIMIT 1 OFFSET 1;

--Subquery
SELECT order_id , total_amount 
FROM orders 
WHERE total_amount = (
	SELECT MAX(total_amount) 
	FROM orders 
	WHERE total_amount < (SELECT MAX(total_amount) FROM orders)
	);


-- W3. [Zomato-style] Find customers who placed orders on
-- consecutive days (order on day N and day N+1).
-- Show customer_name, order_date, next_order_date.


WITH customer_orders AS (
    SELECT
        customer_name,
        order_date,
        LEAD(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS next_order_date
    FROM orders o
    JOIN customers c
    ON c.customer_id = o.customer_id
)
SELECT customer_name,order_date, next_order_date
FROM customer_orders 
WHERE next_order_date = order_date + INTERVAL '1 day';


-- W4. [Swiggy-style] For each city, find the customer with
-- the most orders. If tied, pick the one with
-- higher total spend. Show city, customer_name, order_count.


WITH customer_summary AS (
SELECT 
	city, customer_name , COUNT(order_id) AS order_count,
	SUM(total_amount) AS total_spend
	FROM customers c 
	JOIN orders o ON c.customer_id = o.customer_id 
	GROUP BY customer_name ,city
),
ranked AS (
	SELECT * , 
	ROW_NUMBER() OVER(
		PARTITION BY city
		ORDER BY order_count DESC , total_spend DESC
	) AS rn
	FROM customer_summary
)
SELECT city,customer_name , order_count 
FROM ranked
WHERE rn = 1;


-- W5. [Google-style] Calculate the 7-day rolling average
-- of daily revenue. Show order_date and rolling_avg_revenue.
-- Use AVG() OVER with ROWS BETWEEN 6 PRECEDING AND CURRENT ROW.


WITH daily_revenue AS (
	SELECT 
		order_date,
		SUM(total_amount) AS daily_revenue
	FROM orders 
	GROUP BY order_date
),
rolling_avg AS (
	SELECT 
		order_date,
		daily_revenue,
		AVG(daily_revenue) OVER(ORDER BY order_date
			ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg_revenue
	FROM daily_revenue
)
SELECT order_date, rolling_avg_revenue
FROM rolling_avg;
		


-- ## 🟡 Mid-Level (Asked at data analyst roles)

-- M1. [Meta-style] You have an orders table. Write a query to
-- find the percentage of customers who made a repeat purchase
-- (more than 1 order). Return a single percentage value.


WITH customer_orders AS(
	SELECT customer_name , COUNT(*) AS order_count
	FROM customers c 
	JOIN orders o ON c.customer_id = o.customer_id
	GROUP BY customer_name
)
SELECT 
	ROUND(
		COUNT(CASE WHEN order_count > 1 THEN 1 END) * 100.0 / COUNT(*),2
		) AS repeat_purchase_per
FROM customer_orders;


-- M2. [LinkedIn-style] Find months where revenue DECREASED
-- compared to the previous month. Show month, revenue,
-- prev_revenue, and decline_amount.


WITH monthly AS (
	SELECT 
		DATE_TRUNC('month',order_date) AS month,
		SUM(total_amount) AS revenue 
	FROM orders 
	GROUP BY DATE_TRUNC('month',order_date)
),
cal_rev AS (
	SELECT 
    month,revenue,
		LAG(revenue) OVER(ORDER BY month) AS prev_rev,
		revenue - LAG(revenue) OVER(ORDER BY month) AS decline_amount
	FROM monthly
)
SELECT month ,revenue,prev_rev,decline_amount
FROM cal_rev 
WHERE decline_amount < 0;


-- M3. [Uber-style] Create a cohort retention table.
-- For each acquisition cohort (month of first order),
-- show how many customers placed an order in the
-- SAME month as their first order.
-- (This is Month 0 retention — 100% by definition,
-- but write the query structure correctly.)


WITH first_ord AS (
			SELECT customer_name , MIN(order_date) AS first_order
			FROM customers c 
			JOIN orders o ON c.customer_id = o.customer_id 
			GROUP BY customer_name
),
same_ord AS(
SELECT 
	customer_name , 
	DATE_TRUNC('month', first_order) AS cohort_month
FROM first_ord
GROUP BY customer_name , DATE_TRUNC('month', first_order)
ORDER BY DATE_TRUNC('month', first_order)
)
SELECT customer_name , cohort_month
FROM same_ord
WHERE cohort_month = (
	SELECT MIN(order_date) AS first_order
	FROM orders
),
	COUNT(*) AS month0_customers 
GROUP BY DATE_TRUNC('month', first_order) 
ORDER BY cohort_month;


-- M4. [Netflix-style] Classify customers into RFM segments:
-- R (Recency): days since last order
-- F (Frequency): total number of orders
-- M (Monetary): total amount spent
-- Show customer_name, recency_days, frequency, monetary.
-- Order by monetary DESC.


WITH classification AS (
SELECT 
	customer_name ,
		MAX(order_date) AS last_order,
		COUNT(*) AS Frequency,
		SUM(total_amount) AS Monetary
	FROM orders o
	JOIN customers c ON c.customer_id = o.customer_id
	GROUP BY customer_name 
) 
SELECT 
	customer_name , 
	CURRENT_DATE - last_order AS recency_days,
	Frequency,Monetary
FROM classification 
ORDER BY Monetary DESC;


-- M5. [Stripe-style] Find customers whose spending is
-- increasing over time — each order higher than the previous.
-- Show customer_name and order_date.
-- Use LAG to compare consecutive orders.


WITH customer_analysis AS (
	SELECT 
		customer_name, total_amount,
		order_date
	FROM customers c 
	JOIN orders o ON c.customer_id = o.customer_id 
),
cal AS (
	SELECT customer_name,total_amount, order_date ,
		total_amount - LAG(total_amount) OVER(PARTITION BY customer_name 
		ORDER BY order_date) AS previous_amt
	FROM customer_analysis
)
SELECT 
	customer_name , order_date ,total_amount, previous_amt
	FROM cal 
	WHERE total_amount > previous_amt;


-- ## 🔴 Hard (Asked at senior/data science roles)

-- H1. [Google-style] Write a query that detects revenue anomalies.
-- A day is anomalous if its revenue is more than 2 standard
-- deviations from the 7-day rolling average.
-- Show order_date, daily_revenue, rolling_avg, rolling_stddev,
-- and is_anomaly (TRUE/FALSE).


WITH anomalies AS(
	SELECT 
		order_date, SUM(total_amount) AS revenue
	FROM orders 
	GROUP BY order_date
),
cal AS (
	SELECT 
	order_date,revenue,
		AVG(revenue) OVER(ORDER BY order_date
			ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg_revenue,
		STDDEV(revenue) OVER(ORDER BY order_date
			ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_stddev
	FROM anomalies 
)
SELECT order_date , revenue AS daily_revenue, rolling_avg_revenue, rolling_stddev,
	CASE 
		WHEN ABS(revenue - rolling_avg_revenue) > 2*rolling_stddev THEN TRUE
		ELSE FALSE 
	END AS is_anomaly
FROM cal;


-- H2. [Amazon-style] Build a full customer lifetime value (CLV)
-- model in SQL:
-- CLV = total_spent / months_active * 12
-- where months_active = months between first and last order
-- (minimum 1 to avoid division by zero).
-- Show customer_name, total_spent, months_active, annual_clv.
-- Rank by annual_clv DESC.


WITH customer_summ AS (
	SELECT customer_name , 
	SUM(total_amount) AS total_spent,
	MAX(order_date) AS last_order,
	MIN(order_date) AS first_order
	FROM customers c 
	JOIN orders o ON c.customer_id = o.customer_id 
	GROUP BY customer_name
),
cal AS(
	SELECT customer_name , total_spent,
	GREATEST(
		1,
		DATE_PART('month', AGE(last_order, first_order)) 
		)AS month_active
	FROM customer_summ
)
SELECT customer_name , total_spent, month_active,
	total_spent / month_active * 12 AS annual_clv
	FROM cal
	ORDER BY annual_clv DESC;


-- H3. [Meta-style] Find the longest streak of consecutive days
-- where at least one order was placed.
-- Show streak_start, streak_end, streak_length_days.
-- Hint: This is a gaps-and-islands problem. Use DATE -
-- ROW_NUMBER() technique to group consecutive dates.


WITH dates AS ( 
	SELECT
		DISTINCT order_date 
	FROM orders 
),
grp AS (
	SELECT 
		order_date,
		order_date - CAST(ROW_NUMBER() OVER(ORDER BY order_date) AS INT) AS grp
	FROM dates
)
SELECT MIN(order_date) AS streak_start,
		MAX(order_date) AS streak_end,
		COUNT(*) AS streak_length_days
FROM grp 
GROUP BY grp
ORDER BY streak_length_days DESC 
LIMIT 1;
