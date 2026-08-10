-- Q7. [Advanced Analytics]
-- Calculate a 3-month rolling average of revenue per customer.
-- Only include customers who have ordered in at least 3 different months.
-- Show customer_name, month, monthly_revenue, rolling_3m_avg.

WITH monthly AS (
    SELECT dc.customer_name,
        DATE_TRUNC('month', fo.order_date) AS month,
        ROUND(SUM(foi.unit_price * foi.quantity *
              (1 - foi.discount_pct/100.0)), 2) AS monthly_revenue
    FROM dim_customers dc
    JOIN fact_orders fo ON dc.customer_id = fo.customer_id
    JOIN fact_order_items foi ON fo.order_id = foi.order_id
    GROUP BY dc.customer_id, dc.customer_name,
             DATE_TRUNC('month', fo.order_date)
),
qualified AS (
    SELECT customer_name
    FROM monthly
    GROUP BY customer_name
    HAVING COUNT(DISTINCT month) >= 3
)
SELECT m.customer_name, m.month, m.monthly_revenue,
    ROUND(AVG(m.monthly_revenue) OVER (
        PARTITION BY m.customer_name
        ORDER BY m.month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3m_avg
FROM monthly m
JOIN qualified q ON m.customer_name = q.customer_name
ORDER BY m.customer_name, m.month;


-- Q8. [System Design + SQL]
-- You're told the ecommerce company wants to build
-- a real-time fraud detection system.
-- An order is suspicious if:

-- - total_amount > 3x the customer's historical average order value, OR
-- - It's placed within 10 minutes of a previous order by same customer, OR
-- - The delivery city differs from customer's registered city

-- Write a SQL query that flags suspicious orders.
-- Show order_id, customer_name, flag_reason.
-- (You don't have a timestamp column — use order_date as proxy
-- and think about what you CAN detect with available data)


WITH customer_avg AS (
    SELECT fo.customer_id,
        AVG(foi.unit_price * foi.quantity *
            (1 - foi.discount_pct/100.0)) AS avg_order_value
    FROM fact_orders fo
    JOIN fact_order_items foi ON fo.order_id = foi.order_id
    GROUP BY fo.customer_id
),
order_totals AS (
    SELECT fo.order_id, fo.customer_id, fo.city AS delivery_city,
        fo.order_date,
        ROUND(SUM(foi.unit_price * foi.quantity *
              (1 - foi.discount_pct/100.0)), 2) AS order_amount
    FROM fact_orders fo
    JOIN fact_order_items foi ON fo.order_id = foi.order_id
    GROUP BY fo.order_id, fo.customer_id, fo.city, fo.order_date
)
SELECT ot.order_id, dc.customer_name,
    CASE
        WHEN ot.order_amount > 3 * ca.avg_order_value
            THEN 'High value anomaly'
        WHEN ot.delivery_city != dc.city
            THEN 'City mismatch'
        ELSE 'Multiple flags'
    END AS flag_reason
FROM order_totals ot
JOIN dim_customers dc ON ot.customer_id = dc.customer_id
JOIN customer_avg ca ON ot.customer_id = ca.customer_id
WHERE ot.order_amount > 3 * ca.avg_order_value
   OR ot.delivery_city != dc.city;


-- Q9. [Optimization]
-- You're given this slow query:
-- SELECT c.customer_name, c.city,
-- COUNT(o.order_id) AS order_count,
-- SUM(oi.unit_price * oi.quantity) AS revenue
-- FROM dim_customers c
-- LEFT JOIN fact_orders o ON c.customer_id = o.customer_id
-- LEFT JOIN fact_order_items oi ON o.order_id = oi.order_id
-- WHERE c.state = 'Maharashtra'
-- AND o.status = 'delivered'
-- AND EXTRACT(YEAR FROM o.order_date) = 2024
-- GROUP BY c.customer_id, c.customer_name, c.city
-- ORDER BY revenue DESC;

-- Do THREE things:
-- 1. Identify every performance problem in this query
-- 2. Rewrite it to be optimized
-- 3. List what indexes you would create

WITH filtered_orders AS (
    SELECT 
        o.customer_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.unit_price * oi.quantity) AS revenue
    FROM fact_orders o
    INNER JOIN fact_order_items oi 
        ON o.order_id = oi.order_id
    WHERE o.status = 'delivered'
      AND o.order_date >= '2024-01-01' 
      AND o.order_date < '2025-01-01'
    GROUP BY o.customer_id
)
SELECT 
    c.customer_name,
    c.city,
    fo.order_count,
    fo.revenue
FROM dim_customers c
INNER JOIN filtered_orders fo 
    ON c.customer_id = fo.customer_id
WHERE c.state = 'Maharashtra'
ORDER BY fo.revenue DESC;
