-- Q1. [Schema Awareness]
-- You're given a table called 'sessions' with columns:
-- session_id, user_id, start_time, end_time, page_visited.
-- Write a query to find the average session duration in minutes
-- for each page, only for sessions longer than 2 minutes.
-- Show page_visited and avg_duration_minutes.
-- (Write this without seeing the data — use your schema intuition)


SELECT 
	page_visited , 
	EXTRACT(EPOCH FROM (end_time - start_time)) / 60 AS avg_duration_minutes
FROM sessions
GROUP BY page_visited
HAVING EXTRACT(EPOCH FROM AVG(end_time - start_time)) / 60 > 2;


-- Q2. [Window Functions]
-- Using your ecommerce tables from Day 19, rank customers
-- by total revenue. Show customer_name, total_revenue, rank.
-- Use DENSE_RANK. Customers with no orders should show rank NULL.
-- Hint: think about which JOIN type handles this correctly.

-- -- Your version used INNER JOIN → excludes no-order customers
-- -- Fix: LEFT JOIN + NULLIF for rank

WITH customer_revenue AS (
    SELECT dc.customer_name,
        ROUND(SUM(foi.unit_price * foi.quantity *
              (1 - foi.discount_pct/100.0)), 2) AS total_revenue
    FROM dim_customers dc
    LEFT JOIN fact_orders fo ON dc.customer_id = fo.customer_id
    LEFT JOIN fact_order_items foi ON fo.order_id = foi.order_id
    GROUP BY dc.customer_id, dc.customer_name
)
SELECT customer_name, total_revenue,
    CASE WHEN total_revenue IS NULL THEN NULL
         ELSE DENSE_RANK() OVER (ORDER BY total_revenue DESC NULLS LAST)
    END AS rank
FROM customer_revenue;


-- Q3. [Data Quality]
-- You're told the fact_orders table has duplicate order_ids
-- due to a pipeline bug. Write a query to identify duplicates
-- and return the order_ids that appear more than once.

SELECT 
	order_id , COUNT(*) AS total_orders 
FROM fact_orders
GROUP BY order_id
HAVING COUNT(*) > 1;
