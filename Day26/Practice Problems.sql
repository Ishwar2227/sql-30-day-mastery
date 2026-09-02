-- FQ1. This query has the double aggregation error from Day 25 Q2.
--      Fix it to correctly show state revenue and pct_of_total:

WITH state_rev AS (
    SELECT state, SUM(revenue) AS state_revenue
    FROM fact_orders fo
    JOIN fact_order_items fi ON fo.order_id = fi.order_id
    GROUP BY state
)
SELECT state,
    state_revenue,
    state_revenue * 100.0 / SUM(state_revenue) OVER()
    AS pct_of_total
FROM state_rev
GROUP BY state, state_revenue
ORDER BY state_revenue DESC;

-- FQ2. This query should show monthly active vs inactive customers.
--      The multi-condition JOIN is wrong. Fix it:

WITH monthly AS (
    SELECT DISTINCT DATE_TRUNC('month', order_date) AS month
    FROM fact_orders
),
customers AS (
    SELECT DISTINCT customer_id FROM dim_customers
)
SELECT m.month, c.customer_id,
    CASE WHEN fo.customer_id IS NOT NULL THEN 'active' ELSE 'inactive' END
    AS status
FROM monthly m
CROSS JOIN customers c
LEFT JOIN fact_orders fo ON c.customer_id = fo.customer_id
	AND m.month = DATE_TRUNC('month',fo.order_date);
	

-- FQ3. This query should find customers who spend more than
--      the average spend of customers in their own city.
--      The correlated subquery placement is wrong. Fix it:

WITH customer_totals AS (
    SELECT
        c.customer_id, c.customer_name, c.city,
        SUM(
            foi.unit_price * foi.quantity
        ) AS total_spent
    FROM dim_customers c
    JOIN fact_orders fo ON c.customer_id = fo.customer_id
    JOIN fact_order_items foi ON fo.order_id = foi.order_id
    GROUP BY
        c.customer_id, c.customer_name, c.city
),
city_averages AS (
    SELECT
        *,
        AVG(total_spent) OVER (
            PARTITION BY city
        ) AS city_avg_spend
    FROM customer_totals
)
SELECT
    customer_name,
    city,
    total_spent
FROM city_averages
WHERE total_spent > city_avg_spend;