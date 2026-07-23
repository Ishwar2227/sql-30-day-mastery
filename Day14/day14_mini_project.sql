-- Mini Project — "Interview Simulation"
-- Treat this like a real 45-minute technical interview. Set a timer. No ChatGPT. No hints from me.

-- Question 1 (10 min):
-- Find the top 2 customers by revenue in each city. If a city has fewer than 2 customers with orders, show what's available. Show city, customer_name, total_spent, city_rank.

-- Question 2 (10 min):
-- Calculate month-over-month revenue growth. Flag months where growth exceeded 20% as 'High Growth' and months where revenue declined as 'Decline'. Show month, revenue, growth_pct, flag.

-- Question 3 (15 min):
-- Build a customer health score (0-100) using:
-- - 40 points if total_spent > 1000
-- - 30 points if order_count > 1
-- - 20 points if has a non-null email
-- - 10 points if signed up before 2024 (early adopter)
-- Show customer_name, total_spent, order_count, health_score, grade:
-- - Score >= 70 → 'Healthy'
-- - Score >= 40 → 'At Risk'
-- - Score < 40 → 'Churned'

-- Question 4 (10 min):
-- Find customers who haven't placed any order in the last 60 days relative to the most recent order date in the dataset. Show customer_name, city, last_order_date, days_since_order.

-- 3-line comment on each question explaining your approach before the SQL.


--Shows top 2 customers per city who has highest spendings 
-- shows thier total spending and rank in the city 
WITH customer_summ AS (
	SELECT 
		customer_name ,city,
		SUM(total_amount) AS total_spent,
		RANK() OVER(PARTITION BY city ORDER BY SUM(total_amount) DESC) AS city_rank
	FROM customers c
	JOIN orders o ON c.customer_id = o.customer_id 
	GROUP BY customer_name ,city
)
SELECT customer_name,city , total_spent,
city_rank
FROM customer_summ
WHERE city_rank <= 2;

--shows month over month revenue 
--shows whether the revenue increased or decreased 
--shows percentage of grow
WITH monthly_rev AS (
	SELECT 
		DATE_TRUNC('month',order_date) AS month,
		SUM(total_amount) AS revenue
	FROM orders 
	GROUP BY DATE_TRUNC('month',order_date)
),
pct_cal AS (
	SELECT month,revenue,
	LAG(revenue) OVER(ORDER BY month) AS prev_rev
	FROM monthly_rev
)
SELECT 
	month,revenue,
		ROUND(
		(revenue - prev_rev) * 100.0 /prev_rev,2) AS growth_pct,
	CASE 
		WHEN ROUND(
		(revenue - prev_rev) * 100.0 /prev_rev,2) > 20 
		THEN 'High growth'
		
		WHEN revenue < prev_rev THEN 'Decline'
		ELSE 'normal' 
	END AS flag
FROM pct_cal;

--customer health score where gives points to each customers on basis 
--of spendings and orders 
--customers who scores more than 70 points are healthly customers 
--customers who are less than 40 are churned 
WITH customer_score AS(
	SELECT customer_name , email,signup_date,
	SUM(total_amount) AS total_spent,
	COUNT(order_id) AS order_count
	FROM customers c 
	JOIN orders o ON c.customer_id = o.customer_id 
	GROUP BY customer_name ,email,signup_date
),
health_scores AS (
	SELECT 
	customer_name , email,signup_date,total_spent,order_count,
	(
		(CASE WHEN total_spent > 1000 THEN 40 ELSE 0 END)
		+
		(CASE WHEN order_count > 1 THEN 30 ELSE 0 END)
		+
		(CASE WHEN email IS NOT NULL THEN 20 ELSE 0 END)
		+
		(CASE WHEN signup_date < '2024-01-01' THEN 10 ELSE 0 END)
	) AS health_score
		FROM customer_score
		GROUP BY customer_name,email,signup_date,total_spent,order_count
)
SELECT *,
	CASE 
		WHEN health_score >= 70 THEN 'Healthy'
		WHEN health_score >= 40 THEN 'At risk'
		WHEN health_score < 40 THEN 'Churned'
	END AS grade
FROM health_scores;

--shows customers who haven't place any order in last 60 days 
--compare to other customer's recent order date
--Helps to find the customers who are not active 

WITH customer_repo AS (
	SELECT customer_name,city,
	MAX(order_date) AS last_order_date
	FROM customers c
	JOIN orders o ON c.customer_id = o.customer_id 
	GROUP BY customer_name,city
)
SELECT 
	customer_name , city,last_order_date,
	(
		(SELECT MAX(order_date) FROM orders) - last_order_date
	) AS days_since_order
FROM customer_repo
WHERE (
		(SELECT MAX(order_date) FROM orders) - last_order_date
	) > 60;
