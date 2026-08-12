-- The technique: create a 0/1 flag for each row, then use a rolling SUM window to count consecutive 1s.
-- **Template:**

WITH flags AS (
    SELECT entity, period,
        CASE WHEN [condition met] THEN 1 ELSE 0 END AS flag
    FROM ...
),
rolling AS (
    SELECT entity, period, flag,
        SUM(flag) OVER (
            PARTITION BY entity
            ORDER BY period
            ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
        ) AS consecutive_count
    FROM flags
)
SELECT DISTINCT entity, period
FROM rolling
WHERE consecutive_count = 2;


-- **Practice Problem 1:**
-- Using your ecommerce tables — find customers who placed orders in at least 3 consecutive months. Show customer_name and the streak months.

WITH monthly_orders AS(
	SELECT 
		dc.customer_id,
		dc.customer_name , 
		DATE_TRUNC('month',fo.order_date) AS month,
	FROM dim_customers dc
	JOIN fact_orders fo ON dc.customer_id = fo.customer_id 
),
numbered AS(
	SELECT 
		customer_id,
		customer_name , month, 
		month - (
			ROW_NUMBER() OVER(PARTITION BY customer_id
				ORDER BY month
			) * INTERVAL '1 month'
		) AS grp
	FROM monthly_orders
),
streak AS(
	SELECT 
		customer_id, customer_name ,
		grp, COUNT(*) AS streak_months
	FROM numbered
	GROUP BY customer_id , customer_name , grp
) 
SELECT 
	customer_name , streak_months
FROM streak 
WHERE streak_months >= 3
ORDER BY streak_months DESC;


-- **Practice Problem 2:**
-- Find products that were ordered in at least 2 consecutive months. Show product_name and the months.


WITH product_details AS(
SELECT 
		product_name , 
		DATE_TRUNC('month',fo.order_date) AS month,
		COUNT(fo.order_id) AS order_count,
		CASE
			WHEN COUNT(fo.order_id) > 1 THEN 1
			ELSE 0 
		END AS flags
	FROM dim_products dp
	JOIN fact_order_items foi ON dp.product_id = foi.product_id 
	JOIN fact_orders fo ON foi.order_id = fo.order_id 
	GROUP BY product_name , DATE_TRUNC('month',fo.order_date),fo.order_id
),
rolling AS(
	SELECT product_name, month, 
	SUM(flags) OVER(PARTITION BY product_name
		ORDER BY month
			ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
	) AS consective_count
FROM product_details
)
SELECT 
	product_name , month
FROM rolling
WHERE consective_count = 2;


