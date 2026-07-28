-- Mini Project — "BI Dashboard Build"

-- Your manager says:
-- > "Build me a complete business intelligence report I can present to the board. I need revenue trends with status breakdown, customer value distribution, KPI summary, and top performer analysis."*
-- > 

-- Section 1 — Revenue Pivot:
-- Monthly revenue broken down by status (delivered, cancelled, processing, shipped). Add a total_monthly_revenue column.

-- Section 2 — Customer Value Distribution:
-- Quintile analysis — how much revenue comes from each 20% of customers. Show quintile, customer_count, quintile_revenue, pct_of_total.

-- Section 3 — KPI Summary:
-- Single row showing total_revenue, total_customers, arpu, avg_order_value, repeat_purchase_rate.

-- Section 4 — Top Performers:
-- Top 3 customers by CLV (annual_clv from Day 14 H2 formula). Show customer_name, city, total_spent, months_active, annual_clv.
-- 3-line comment per section. All four sections required.


--Section 1
--shows total revenue generated from delivered order , cancelled order 
-- shows total revenue generated from processing and shipped orders 
--and also shows overall total montly revenue from every status  
SELECT 
	DATE_TRUNC('month',order_date) AS month,
	SUM(CASE WHEN status='delivered' THEN total_amount ELSE 0 END) AS delivered,
	SUM(CASE WHEN status='cancelled' THEN total_amount ELSE 0 END) AS cancelled,
	SUM(CASE WHEN status='processing' THEN total_amount ELSE 0 END) AS processing,
	SUM(CASE WHEN status = 'shipped' THEN total_amount ELSE 0 END) AS shipped,
	SUM(total_amount) AS total_monthly_revenue
FROM orders 
GROUP BY DATE_TRUNC('month',order_date);

--Section 2 
--shows how much revenue is generated from 20% of customers 
--shows in which quintile the customer comes 
--shows overall revenue of quintile, % of total 
WITH customer_spend AS(
	SELECT 
		customer_id , customer_name ,
		SUM(total_amount) AS total_revenue
	FROM orders o 
	JOIN customers c ON c.customer_id = o.customer_id
	GROUP BY customer_id , customer_name 
),
ranked AS(
	SELECT 
		customer_id,customer_name , total_spent,
		NTILE(5) OVER(ORDER BY total_spent)  AS quintile
	FROM customer_spend
)
SELECT 
	quintile,
	COUNT(*) AS customer_count,
	SUM(total_spent) AS quintile_revenue,
	ROUND(
		SUM(total_spent) * 100.0
		/SUM(SUM(total_spent)) OVER(),2
	) AS pct_of_total
FROM ranked 
GROUP BY quintile
ORDER BY quintile;

--Section 3 - KPI summary
-- single row describing total revenue , count of customers , avg order value 
-- repeat purchase rate from a customer  
WITH customer_count AS(
	SELECT 
		customer_id,
		COUNT(*) AS order_count
	FROM orders 
	GROUP BY customer_id
)
SELECT 
	SUM(total_amount) AS total_revenue,
	COUNT(customer_id) AS total_customers,
	SUM(total_amount) / COUNT(DISTINCT customer_id) AS arpu,
	AVG(total_amount) AS avg_order_value,
	(
		SELECT COUNT(CASE WHEN order_count > 1 THEN 1 END) * 100.0
		/COUNT(*) 
		FROM customer_count
	) AS repeat_purchase_rate 
FROM orders;

--Section 4 - Top performers 
--shows top customer names their city and total spending 
--shows how much time they were active  
WITH top_customers AS(
	SELECT 
		customer_name , city, 
		SUM(total_amount) AS total_spent,
		MIN(order_date) AS first_order,
		MAX(order_date) AS last_order
	FROM customers c 
	JOIN orders o ON c.customer_id = o.customer_id 
	GROUP BY customer_name, city
),
cal AS(
	SELECT customer_name , city,
		total_spent,
		GREATEST(
			1, DATE_PART('month',AGE(last_order,first_order))
		) AS months_active
	FROM top_customers 
)
SELECT customer_name , city,total_spent,months_active,
	total_spent / months_active * 12 AS annual_clv
FROM cal 
ORDER BY annual_clv DESC
LIMIT 3;
