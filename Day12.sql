-- Mini Project — "Executive Analytics Dashboard"
-- Your manager says
-- I need a complete monthly business review. Show me revenue trends, 
--customer acquisition, repeat vs one-time buyer breakdown, and our top customers. This will go to the CEO."*


-- Build four queries — each a separate section of the dashboard:

-- Section 1 — Revenue Trend:
-- Month, monthly revenue, previous month revenue, growth % — ordered by month.

-- Section 2 — Customer Acquisition:
-- Month of first purchase (cohort_month), new customers that month, cumulative customers acquired to date.

-- Section 3 — Buyer Segmentation:
-- Total customers, repeat_buyers count, one_time_buyers count, repeat_buyer_pct. All in one row.

-- Section 4 — Top 3 Customers Overall:
-- customer_name, city, total_spent, spend_rank — only top 3.

-- 3-line comment above each section explaining what it shows and why it matters to the business.

--Section 1 revenue trend
--This shows the monthly revenue , previous months revenue 
--Growth percentage per month  
WITH monthly AS (
		SELECT 
				DATE_TRUNC('month',order_date) AS month,
				SUM(total_amount) AS monthly_revenue
		FROM orders 
		GROUP BY DATE_TRUNC('month',order_date)
)
SELECT month,monthly_revenue, 
	LAG(monthly_revenue) OVER (ORDER BY month) AS prev_month_revenue,
	ROUND(
		(monthly_revenue- LAG(monthly_revenue) OVER (ORDER BY month))
		* 100.0 
		/ LAG(revenue) OVER (ORDER BY month),2) AS growth_pct
	FROM monthly;

--SECTION 2 customer acquisition
--months of first purchase by customer 
--New customers purchase count that month 
--Also displays cumulative customer growth over time. 
WITH first_purchase AS (
    SELECT customer_id, 
           MIN(order_date) AS first_order_date
    FROM orders 
    GROUP BY customer_id
),
cohorts AS(
	SELECT 
			DATE_TRUNC('month',first_order_date) AS cohort_month,
			COUNT(*) AS new_customers 
	FROM first_purchase
	GROUP BY DATE_TRUNC('month',first_order_date)
)
SELECT cohort_month,
		new_customers,
		SUM(new_customers) OVER (ORDER BY cohort_month) AS cumulative_customers
	FROM cohorts
	ORDER BY cohort_month;
		
		
--SECTION 3
--shows total customers 
-- repeat buyers count and their percentage
--No.of one time buyers
-- Helps understand customer loyalty.
WITH buyer_seg AS(
		SELECT customer_id ,
		COUNT(order_id) AS order_count
			FROM orders
			GROUP BY customer_id
)
SELECT COUNT(*) AS total_customers, 
		COUNT( 
				CASE WHEN order_count > 1 THEN 1
				END 
		) AS repeat_buyers,
		COUNT(
				CASE WHEN order_count = 1 THEN 1 
				END
		) AS one_time_buyers,
		ROUND(
			COUNT( 
				CASE WHEN order_count > 1 
				THEN 1 
				END
			)* 100.0 /COUNT(*),2) AS repeat_buyer_pct
FROM buyer_seg;
	
	
--SECTION 4
--Top 3 customers names and thier purchases and spendings per city 
--shows top spenders per city 
WITH ranked AS (
		SELECT customer_name , city, SUM(total_amount) AS total_spent,
		DENSE_RANK() OVER ( 
				ORDER BY SUM(total_amount) DESC
				) AS spend_rank
		FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY city, customer_name
 )
 SELECT city, customer_name, total_spent, spend_rank 
FROM ranked
WHERE spend_rank <= 3
ORDER BY spend_rank;;

