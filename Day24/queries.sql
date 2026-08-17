-- B1. For each customer show their name and a comma-separated
-- list of all product names they purchased.
-- Show customer_name and products_list.
-- Use STRING_AGG.

SELECT c.customer_name ,
	STRING_AGG(DISTINCT p.product_name, ', ' ORDER BY p.product_name) AS products_lists
FROM dim_customers c
JOIN fact_orders fo ON c.customer_id = fo.customer_id 
JOIN fact_order_items fi ON fo.order_id = fi.order_id 
JOIN dim_products p ON p.product_id = fi.product_id 
GROUP BY c.customer_id ,c.customer_name ;


-- B2. For each product category show an array of all
-- product names in that category.
-- Show category and product_names_array.
-- Use ARRAY_AGG.

SELECT 
	category,
	ARRAY_AGG(DISTINCT product_name ORDER BY product_name) AS product_names_array
FROM dim_products
GROUP BY category;


-- B3. Generate all 12 months of 2024 as a date series.
-- Show month only. (No table join needed.)


SELECT GENERATE_SERIES(
	'2024-01-01'::DATE,
	'2024-12-01'::DATE,
	'1 month'::INTERVAL
) AS month;


-- B4. Show each customer's name as a JSON object with:
-- customer_id, customer_name, city, age.
-- Use JSON_BUILD_OBJECT.

SELECT 
	customer_name,
	JSON_BUILD_OBJECT(
		'customer_id', customer_id,
		'customer_name',customer_name,
		'city',city,
		'age',age
	) AS customer_json
FROM dim_customers;


-- B5. For each state show:
-- - total orders
-- - delivered orders (FILTER)
-- - cancelled orders (FILTER)
-- - delivered revenue (SUM with FILTER)
-- All in one row per state.

SELECT 
	fo.state,
	COUNT(*) AS total_orders,
	COUNT(*) FILTER(WHERE status = 'delivered') AS delivered_orders,
	COUNT(*) FILTER(WHERE status = 'cancelled') AS cancelled_orders,
	SUM(unit_price * quantity) FILTER(WHERE status = 'delivered') AS delivered_rev
FROM fact_orders fo 
JOIN fact_order_items foi ON fo.order_id = foi.order_id
GROUP BY state;


-- ## 🟡 Intermediate
-- I1. Build a complete monthly revenue report for 2024
-- that shows ALL 12 months — even months with zero orders.
-- Show month and revenue (0 for empty months).
-- Use GENERATE_SERIES + LEFT JOIN.

WITH all_months AS(
	SELECT 
	GENERATE_SERIES(
		'2024-01-01'::DATE,
		'2024-12-01'::DATE,
		'1 month'::INTERVAL
	)::DATE AS month 
),
monthly_revenue AS(
	SELECT DATE_TRUNC('month',order_date)::DATE AS month,
		SUM(unit_price * quantity) AS revenue
	FROM fact_orders fo 
	JOIN fact_order_items fi ON fo.order_id = fi.order_id
	WHERE order_date >= '2024-01-01'
	GROUP BY DATE_TRUNC('month',order_date)::DATE
)	
SELECT 
	am.month,
		COALESCE(mr.revenue,0) AS revenue
FROM all_months am 
LEFT JOIN monthly_revenue mr ON am.month = mr.month
ORDER BY am.month;


-- I2. For each customer, show their purchase history as
-- a JSON array of objects:
-- [{"product": "MacBook Pro", "amount": 118750}, ...]
-- Show customer_name and purchase_history.
-- Use JSON_AGG + JSON_BUILD_OBJECT.

SELECT 
	customer_name , 
	JSON_AGG(
		JSON_BUILD_OBJECT(
			'product',p.product_name,
			'amount', oi.unit_price
	                * oi.quantity
	                * (1 - oi.discount_pct / 100.0)
		)
	ORDER BY p.product_name
) AS purchase_history
FROM dim_customers c
JOIN fact_orders o ON c.customer_id = o.customer_id
JOIN fact_order_items oi ON o.order_id = oi.order_id
JOIN dim_products p ON oi.product_id = p.product_id

GROUP BY
    c.customer_id,c.customer_name
ORDER BY c.customer_name;


-- I3. Find customers who bought products from at least 2 categories.
-- Use ARRAY_AGG to show which categories they bought from.
-- Show customer_name and categories_array.

SELECT 
	c.customer_name , 
	ARRAY_AGG(DISTINCT p.category ORDER BY p.category) AS categories_array
FROM dim_customers c
JOIN fact_orders fo ON c.customer_id = fo.customer_id
JOIN fact_order_items oi ON fo.order_id = oi.order_id
JOIN dim_products p ON oi.product_id = p.product_id
GROUP BY c.customer_id , customer_name;


-- I4. Build a product co-purchase report using STRING_AGG:
-- For each product, show a comma-separated list of other
-- products it was bought with in the same order.
-- Show product_name and bought_with.

SELECT
    p1.product_name,
    STRING_AGG(
        DISTINCT p2.product_name,', ' ORDER BY p2.product_name
    ) AS bought_with
FROM fact_order_items oi1
JOIN fact_order_items oi2 ON oi1.order_id = oi2.order_id
AND oi1.product_id <> oi2.product_id
JOIN dim_products p1 ON oi1.product_id = p1.product_id
JOIN dim_products p2 ON oi2.product_id = p2.product_id
GROUP BY p1.product_id, p1.product_name
ORDER BY p1.product_name;


-- I5. Using GENERATE_SERIES and your retention template from Day 22,
-- build a retention report that covers ALL months Jan-Dec 2024,
-- even months with no customer activity.
-- Show month, new_customers, returning_customers, churned_customers.
-- Months with no activity should show 0s not be missing.

WITH all_months AS(
	SELECT GENERATE_SERIES(
		'2024-01-01'::DATE,
		'2024-12-01'::DATE,
		'1 month'::INTERVAL
	)::DATE AS month
),
user_period AS(
	SELECT 
		c.customer_id ,
		DATE_TRUNC('month',fo.order_date) AS month
	FROM dim_customers c
	JOIN fact_orders fo ON c.customer_id = fo.customer_id 
	GROUP BY c.customer_id , DATE_TRUNC('month',fo.order_date) 
),
first_seen AS(
	SELECT 
		customer_id , MIN(month) AS cust_first_month
	FROM user_period 
	GROUP BY customer_id
),
classification AS(
	SELECT 
		am.month,
		fs.customer_id,
		CASE 
			WHEN fs.cust_first_month = am.month THEN 'new'
			WHEN up.customer_id IS NOT NULL THEN 'returning'
			ELSE 'churned'
		END AS customer_type
	FROM all_months am
	CROSS JOIN first_seen fs
	LEFT JOIN user_period up ON fs.customer_id = up.customer_id
	AND am.month = up.month
	WHERE fs.cust_first_month <= am.month
)
SELECT 
	month,
	COUNT(*) FILTER( WHERE customer_type = 'new') AS new_customers,
	COUNT(*) FILTER(WHERE customer_type = 'returning') AS returning_customers,
	COUNT(*) FILTER(WHERE customer_type = 'churned') AS churned_customers
FROM classification 
GROUP BY month
ORDER BY month;


-- ## 🔴 Challenging

-- C1. Build a customer profile JSON document for each customer:
-- {
-- "name": "Aisha Sharma",
-- "city": "Mumbai",
-- "total_spent": 150000,
-- "orders": 3,
-- "top_category": "Electronics",
-- "products": ["MacBook Pro", "Sony Headphones"]
-- }
-- Use JSON_BUILD_OBJECT + JSON_AGG + subqueries.

SELECT 
	JSON_BUILD_OBJECT(
		'name',c.customer_name,
		'city',c.city,
		'total_spent',SUM(oi.unit_price * quantity *(1-oi.discount_pct / 100.0)) ,
		'orders',COUNT(DISTINCT o.order_id),
		'products',ARRAY_AGG(DISTINCT p.product_name),
		'top_category', ( 
			SELECT p2.category
      FROM fact_orders o2
      JOIN fact_order_items oi2
      ON o2.order_id = oi2.order_id
      JOIN dim_products p2
      ON oi2.product_id = p2.product_id
      WHERE o2.customer_id = c.customer_id
      GROUP BY p2.category
      ORDER BY COUNT(*) DESC
      LIMIT 1
			) AS customer_profile
	)
FROM dim_customers c
JOIN fact_orders o ON c.customer_id = o.customer_id
JOIN fact_order_items oi ON o.order_id = oi.order_id
JOIN dim_products p ON oi.product_id = p.product_id
GROUP BY c.customer_id , c.customer_name, c.city
ORDER BY c.customer_name;


-- C2. Create a monthly cohort heatmap data structure.
-- For each (cohort_month, activity_month) pair show revenue.
-- Output as rows with:
-- cohort_month, activity_month, cohort_revenue.
-- Use GENERATE_SERIES to ensure all month pairs appear.

WITH customer_cohort AS(
	SELECT 
		customer_id , 
		MIN(DATE_TRUNC('month',order_date)) AS cohort_month
	FROM fact_orders 
	GROUP BY customer_id
),
actual_revenue AS (
    SELECT
        cc.cohort_month,
        DATE_TRUNC('month', fo.order_date)::DATE AS activity_month,
        SUM(
            oi.unit_price
            * oi.quantity
            * (1 - oi.discount_pct / 100.0)
        ) AS revenue
    FROM customer_cohort cc
    JOIN fact_orders fo
        ON cc.customer_id = fo.customer_id
    JOIN fact_order_items oi
        ON fo.order_id = oi.order_id
    GROUP BY
        cc.cohort_month,
        DATE_TRUNC('month', fo.order_date)::DATE
),
all_months AS (
    SELECT
        GENERATE_SERIES(
            '2024-01-01'::DATE,
            '2024-12-01'::DATE,
            '1 month'::INTERVAL
        )::DATE AS month
),

cohort_months AS (
    SELECT DISTINCT
        cohort_month
    FROM customer_cohort
),

all_pairs AS (
    SELECT
        cm.cohort_month,
        am.month AS activity_month
    FROM cohort_months cm
    CROSS JOIN all_months am
    WHERE am.month >= cm.cohort_month
)
SELECT
    ap.cohort_month,
    ap.activity_month,
    COALESCE(ar.revenue, 0) AS cohort_revenue
FROM all_pairs ap
LEFT JOIN actual_revenue ar
    ON ap.cohort_month = ar.cohort_month
    AND ap.activity_month = ar.activity_month
ORDER BY
    ap.cohort_month,
    ap.activity_month;


-- C3. Find customers whose product purchase sequence
-- shows a pattern: bought Electronics first, then Fashion.
-- Use ARRAY_AGG with ORDER BY order_date to build
-- the category sequence, then filter on array contents.
-- Show customer_name and category_sequence.

SELECT 
	ARRAY_AGG(
		p.category,
		ORDER BY o.order_date
	) AS category_sequence
FROM dim_customers c
JOIN fact_orders o
    ON c.customer_id = o.customer_id
JOIN fact_order_items oi
    ON o.order_id = oi.order_id
JOIN dim_products p
    ON oi.product_id = p.product_id
GROUP BY
    c.customer_id,
    c.customer_name
HAVING
    array_position(
        ARRAY_AGG(p.category ORDER BY o.order_date),
        'Electronics'
    )
    <
    array_position(
        ARRAY_AGG(p.category ORDER BY o.order_date),
        'Fashion'
    )

ORDER BY
    c.customer_name;
