-- C1. Cohort analysis: for each month, show how many
-- new customers made their first-ever purchase.
-- Show cohort_month and new_customers.
WITH monthly AS (
		SELECT customer_id, 
		MIN(order_date) AS first_order_date
		FROM orders 
		GROUP BY customer_id
)
SELECT DATE_TRUNC('month',first_order_date) AS cohort_month,
		COUNT(*) AS new_customers
FROM monthly
GROUP BY cohort_month
ORDER BY cohort_month;


-- C2. For each customer show:
-- - their name
-- - date of first order
-- - date of most recent order
-- - number of days between first and last order (tenure)
-- - total orders
-- - classification: 'Active' if last order within 60 days
-- of the most recent order in the whole dataset,
-- otherwise 'Churned'
-- This is a real churn analysis pattern.

WITH customer_analysis AS (
    SELECT
        c.customer_name,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS most_recent_order,
        MAX(o.order_date) - MIN(o.order_date) AS tenure_days,
        COUNT(o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_name
)

SELECT
    customer_name,
    first_order_date,
    most_recent_order,
    tenure_days,
    total_orders,
    CASE
        WHEN (
            SELECT MAX(order_date)
            FROM orders
        ) - most_recent_order <= 60
        THEN 'Active'
        ELSE 'Churned'
    END AS classification
FROM customer_analysis
ORDER BY customer_name;


-- C3. Find the month with the highest revenue.
-- Then show all orders placed in that month.
-- Use a subquery to find the month, then filter orders.
-- Show order_id, customer_name, order_date, total_amount.
SELECT
    o.order_id,
    c.customer_name,
    o.order_date,
    o.total_amount
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
WHERE DATE_TRUNC('month', o.order_date) = (

    SELECT DATE_TRUNC('month', order_date)
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
    ORDER BY SUM(total_amount) DESC
    LIMIT 1

)
ORDER BY o.order_date;
