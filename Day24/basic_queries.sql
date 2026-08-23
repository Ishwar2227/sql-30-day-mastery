-- B1. Build a basic feature table for each customer:
-- customer_id, total_orders, total_spent, avg_order_value,
-- max_single_order, days_since_first_order, days_since_last_order.
-- Use fact_orders + fact_order_items. Revenue formula with discount.
-- days_since = relative to MAX(order_date) in the dataset.

WITH customer_info AS(
	SELECT
			customer_id , 
			COUNT(DISTINCT fo.order_id) AS total_orders,
			SUM(unit_price * quantity * (1 - discount_pct/100.0)) AS total_spent,
			MAX(
            (
                SELECT SUM(
                    fi2.unit_price
                    * fi2.quantity
                    * (1 - fi2.discount_pct / 100.0)
                )
                FROM fact_order_items fi2
                WHERE fi2.order_id = fo.order_id
            )
        ) AS max_single_order,
		  MIN(order_date) AS first_order_date,
			MAX(order_date) AS last_order_date
	FROM fact_orders fo 
	JOIN fact_order_items fi ON fo.order_id = fi.order_id
	GROUP BY customer_id 
)
SELECT 
	customer_id , total_orders , total_spent,
	total_spent / NULLIF(total_orders, 0) AS avg_order_value,
	max_single_order,
	(SELECT MAX(order_date) FROM fact_orders) - first_order_date 
	AS days_since_first_order,
	(SELECT MAX(order_date) FROM fact_orders) - last_order_date AS days_since_last_order 
	FROM customer_info
ORDER BY customer_id;


-- B2. Create binary category flags for each customer:
-- bought_electronics (1/0), bought_fashion (1/0), bought_home (1/0).
-- Show customer_id and the three flags.

SELECT 
	customer_id ,
	MAX(CASE WHEN category = 'Electronics' THEN 1 ELSE 0 END) AS bought_electronics,
	MAX(CASE WHEN category = 'Fashion' THEN 1 ELSE 0 END) AS bought_fashion,
	MAX(CASE WHEN category = 'Home' THEN 1 ELSE 0 END) AS bought_home
FROM fact_orders fo 
JOIN fact_order_items fi ON fo.order_id = fi.order_id 
JOIN dim_products dp ON dp.product_id = fi.product_id
GROUP BY customer_id;


-- B3. Add payment method flags:
-- uses_upi (1/0), uses_credit_card (1/0), uses_debit_card (1/0).
-- Show customer_id and the three flags.

SELECT 
	customer_id,
	MAX(CASE WHEN payment_method = 'UPI' THEN 1 ELSE 0 END) AS uses_upi,
	MAX(CASE WHEN payment_method = 'Credit Card' THEN 1 ELSE 0 END) AS uses_credit_card,
	MAX(CASE WHEN payment_method = 'Debit Card' THEN 1 ELSE 0 END) AS uses_debit_card
FROM fact_orders 
GROUP BY customer_id;


-- B4. Calculate spend percentile and decile for each customer.
-- Show customer_id, total_spent, spend_percentile, spend_decile.

WITH customer_info AS(
	SELECT 
		customer_id, 
		ROUND(SUM(unit_price * quantity * (1 - discount_pct/100.0)),2) AS total_spent
	FROM fact_orders fo 
	JOIN fact_order_items fi ON fo.order_id = fi.order_id
	GROUP BY customer_id
)
SELECT 
	customer_id, total_spent,
	PERCENT_RANK() OVER(ORDER BY total_spent) AS spend_percentile,
	NTILE(10) OVER(ORDER BY total_spent) AS spend_decile
FROM customer_info;


-- B5. Create a train/test split for the customer feature table.
-- 70% train, 30% test using MD5 deterministic split.
-- Show customer_id, total_spent, dataset_split.

WITH customer_info AS (
    SELECT
        customer_id,
        ROUND(
            SUM(
                unit_price * quantity *
                (1 - discount_pct / 100.0)
            ), 2
        ) AS total_spent
    FROM fact_orders fo
    JOIN fact_order_items foi
        ON fo.order_id = foi.order_id
    GROUP BY customer_id
),

split AS (
    SELECT
        customer_id,
        total_spent,
        NTILE(10) OVER (
            ORDER BY MD5(customer_id::TEXT)
        ) AS split_bucket
    FROM customer_info
)

SELECT
    customer_id,
    total_spent,
    CASE
        WHEN split_bucket <= 7 THEN 'train'
        ELSE 'test'
    END AS dataset_split
FROM split
ORDER BY customer_id;
