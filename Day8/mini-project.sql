-- Your manager asks:
-- "I need a multi-layered sales report. Show me each customer's total spend, their rank among all customers by spend, what percentage of total revenue they represent, and classify them as High/Mid/Low value. Use CTEs to keep it clean. Sort by spend rank."*

-- Requirements:
-- - Use **at least 2 CTEs** — one for customer spend, one for ranked results
-- - Columns: `customer_name`, `city`, `total_spent`, `spend_rank`, `pct_of_total_revenue`, `value_segment`
-- - `spend_rank` via DENSE_RANK
-- - `pct_of_total_revenue` via window function
-- - `value_segment` via CASE
-- - 3-line comment
-- - No ChatGPT. If you get stuck, write what you have and tell me exactly where you're stuck. I will help you through it.

-- -- Multi-layered customer sales analysis report
-- -- Shows customer spending, ranking, revenue contribution, and segmentation
-- -- Uses CTEs and window functions for clean analytical processing

WITH customer_spend AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.city,
        SUM(o.total_amount) AS total_spent
    FROM customers c
    JOIN orders o 
    ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, c.city
),

ranked_customers AS (
    SELECT 
        customer_name,
        city,
        total_spent,
        DENSE_RANK() OVER (
            ORDER BY total_spent DESC
        ) AS spend_rank,
        ROUND(
            total_spent * 100.0 
            / SUM(total_spent) OVER(),
            2
        ) AS pct_of_total_revenue
    FROM customer_spend
)

SELECT 
    customer_name,
    city,
    total_spent,
    spend_rank,
    pct_of_total_revenue,
    CASE
        WHEN total_spent >= 1000 THEN 'High Value'
        WHEN total_spent >= 500 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS value_segment
FROM ranked_customers
ORDER BY spend_rank;
