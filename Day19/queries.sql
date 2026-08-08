-- B1. What is the total revenue?
-- Revenue = unit_price * quantity * (1 - discount_pct/100)
-- Show a single value: total_revenue.

SELECT ROUND(SUM(unit_price * quantity * (1 - discount_pct/100.0)), 2)
AS total_revenue
FROM fact_order_items;


-- B2. How many orders per status?
-- Show status and order_count.

SELECT status , 
	COUNT(*) AS order_count
FROM fact_orders
GROUP BY status;


-- B3. What are the top 5 products by revenue?
-- Show product_name, category, total_revenue.

SELECT dp.product_name, dp.category,
    ROUND(SUM(fi.unit_price * fi.quantity * (1 - fi.discount_pct/100.0)), 2)
    AS total_revenue
FROM dim_products dp
JOIN fact_order_items fi ON dp.product_id = fi.product_id
GROUP BY dp.product_id, dp.product_name, dp.category
ORDER BY total_revenue DESC
LIMIT 5;


-- B4. How many customers are from each state?
-- Show state and customer_count. ORDER BY customer_count DESC.

SELECT 
	state, COUNT(customer_name) AS customer_count
FROM dim_customers 
GROUP BY state
ORDER BY customer_count DESC;


-- B5. What is the average delivery time in days
-- for delivered orders?
-- Show avg_delivery_days.
-- Use: delivery_date - order_date.

SELECT ROUND(AVG(delivery_date - order_date), 1) AS avg_delivery_days
FROM fact_orders
WHERE status = 'delivered' AND delivery_date IS NOT NULL;


-- ## 🟡 Intermediate Analysis

-- I1. Monthly revenue trend for 2024.
-- Show month, monthly_revenue, cumulative_revenue.

WITH revenue AS(
	SELECT 
		DATE_TRUNC('month',order_date) AS month,
		SUM(unit_price) AS monthly_revenue
	FROM fact_orders f
	JOIN fact_order_items fo ON f.order_id = fo.order_id
	GROUP BY month
)
SELECT 
	month,monthly_revenue,
	SUM(monthly_revenue) OVER(ORDER BY month) AS cumulative_revenue
FROM revenue
GROUP BY month,monthly_revenue;


-- I2. Revenue by category and subcategory.
-- Show category, subcategory, revenue, pct_of_total_revenue.
-- Order by category, then revenue DESC within category.

SELECT 
	category, subcategory, SUM(price) AS revenue,
	price * 100.0 / SUM(price) OVER() AS pct_of_total_revene
FROM dim_products
GROUP BY category, subcategory,price
ORDER BY category, revenue DESC;


-- I3. Customer lifetime value analysis.
-- Show customer_name, state, total_orders,
-- total_revenue, avg_order_value, first_order_date,
-- days_as_customer (days from first to last order or today).

SELECT 
	dc.customer_name , dc.state, COUNT(fo.order_id) AS total_orders,
	SUM(fi.unit_price) AS total_revenue, AVG(fi.unit_price) AS avg_order_value,
	MIN(fo.order_date) AS first_order_date,
	MAX(fo.order_date) - MIN(fo.order_date) AS days_as_customer
FROM dim_customers dc
JOIN fact_orders fo ON dc.customer_id = fo.customer_id
JOIN fact_order_items fi ON fo.order_id = fi.order_id 
GROUP BY customer_name , dc.state;


-- I4. Payment method popularity and revenue breakdown.
-- Show payment_method, order_count, total_revenue,
-- avg_order_value, pct_of_orders.

SELECT 
	fo.payment_method, COUNT(fo.order_id) AS order_count,
	SUM(fi.unit_price) AS total_revenue,
	AVG(fi.unit_price) AS avg_order_value,
	ROUND(
	fo.order_id * 100.0 / COUNT(fo.order_id) OVER(),2) AS pct_of_orders
FROM fact_orders fo
JOIN fact_order_items fi ON fo.order_id = fi.order_id
GROUP BY fo.payment_method, fo.order_id;


-- I5. Product profitability analysis.
-- Revenue = unit_price * quantity * (1 - discount_pct/100)
-- Profit = (unit_price - cost) * quantity * (1 - discount_pct/100)
-- Show product_name, category, total_revenue,
-- total_profit, profit_margin_pct.
-- Order by profit_margin_pct DESC.

SELECT
    dp.product_name,
    dp.category,

    ROUND(
        SUM(fi.unit_price * fi.quantity * (1 - fi.discount_pct / 100.0)),
        2
    ) AS total_revenue,

    ROUND(
        SUM((fi.unit_price - dp.cost) * fi.quantity * (1 - fi.discount_pct / 100.0)),
        2
    ) AS total_profit,

    ROUND(
        (
            SUM((fi.unit_price - dp.cost) * fi.quantity * (1 - fi.discount_pct / 100.0))
            /
            SUM(fi.unit_price * fi.quantity * (1 - fi.discount_pct / 100.0))
        ) * 100,
        2
    ) AS profit_margin_pct

FROM dim_products dp
JOIN fact_order_items fi
ON dp.product_id = fi.product_id

GROUP BY
    dp.product_name,
    dp.category

ORDER BY
    profit_margin_pct DESC;


## 🔴 Advanced Analysis

-- C1. Build a complete customer RFM analysis:
-- R = days since last order (relative to max order date)
-- F = total number of orders
-- M = total revenue from that customer
-- Then score each metric 1-4 using NTILE(4):
-- R score: lower days = higher score (reverse NTILE)
-- F score: more orders = higher score
-- M score: more revenue = higher score
-- Show customer_name, R, F, M, rfm_score (R+F+M),
-- and segment:
-- Score 10-12 → 'Champions'
-- Score 7-9  → 'Loyal Customers'
-- Score 4-6  → 'At Risk'
-- Score 3    → 'Lost'

WITH customer_analysis AS(
	SELECT 
		dc.customer_id ,dc.customer_name , 
		(SELECT MAX(order_date) FROM fact_orders) - MAX(fo.order_date) AS R,
		COUNT(DISTINCT fo.order_id) AS F,
		ROUND(SUM(foi.unit_price * foi.quantity * (1 - foi.discount_pct / 100.0)),2) AS M
	FROM dim_customers dc
	JOIN fact_orders fo ON dc.customer_id = fo.customer_id 
	JOIN fact_order_items foi ON fo.order_id = foi.order_id
	GROUP BY dc.customer_id ,dc.customer_name
),
rfm_scores AS(
	SELECT 
		customer_id,customer_name , R,F,M,
		5 - NTILE(4) OVER(ORDER BY R) AS r_score,
		NTILE(4) OVER(ORDER BY F) AS f_score,
		NTILE(4) OVER(ORDER BY M) AS m_score
	FROM customer_analysis
)
SELECT 
	customer_name , R,F,M, (r_score + f_score + m_score) AS rfm_score,
	CASE
		WHEN(r_score + f_score + m_score) BETWEEN 10 AND 12
			THEN 'Champions'
		WHEN(r_score + f_score + m_score) BETWEEN 7 AND 9
			THEN 'Loyal Champions'
		WHEN(r_score + f_score + m_score) BETWEEN 4 AND 6
			THEN 'At risk'
		ELSE 'Lost'
	END AS segment
FROM rfm_scores
ORDER BY rfm_score DESC, M DESC; 


-- C2. Cohort analysis:
-- Group customers by signup month (cohort).
-- For each cohort show:
-- - cohort_month
-- - cohort_size (customers who signed up)
-- - customers_who_ordered (made at least one order)
-- - conversion_rate (pct who ordered)
-- This shows which acquisition cohorts convert best.

WITH cohort AS(
	SELECT 
		DATE_TRUNC('month',signup_date) AS cohort_month,
		customer_id
	FROM dim_customers
)
SELECT 
	c.cohort_month,
	COUNT(DISTINCT c.customer_id) AS cohort_size,
	COUNT(DISTINCT fo.customer_id) AS customer_who_ordered,
	ROUND(
		COUNT(DISTINCT fo.customer_id) * 100.0 /
		COUNT(DISTINCT c.customer_id),2
	) AS conversion_rate
FROM cohort c
JOIN fact_orders fo ON c.customer_id = fo.customer_id
GROUP BY c.cohort_month
ORDER BY c.cohort_month;


-- C3. Market basket analysis — find product pairs
-- that are frequently bought together.
-- Show product_1, product_2, times_bought_together.
-- Hint: self-join fact_order_items on same order_id
-- where product_id1 < product_id2 to avoid duplicates.

SELECT 
	foi.product_id AS product_1,
	fi.product_id AS product_2,
	COUNT(*) AS time_bought_together
	FROM fact_order_items foi 
JOIN fact_order_items fi ON foi.order_id = fi.order_id
WHERE foi.product_id < fi.product_id
GROUP BY foi.product_id , fi.product_id
ORDER BY time_bought_together DESC;
