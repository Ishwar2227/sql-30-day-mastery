-- C1. Run EXPLAIN ANALYZE on your Day 8 mini project query
-- (the two-CTE window function query).
-- Read the full output. Identify:
-- - The most expensive node (highest actual time)
-- - Whether any indexes are being used
-- - What you would add or change to optimize it
-- Write your findings as SQL comments above the query.
--HashAggregate (actual time=0.428..0.436)
-- no indexes are used 
-- For larger datasets, adding an index on orders(customer_id) would improve JOIN performance 
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


-- C2. A table has 1 million rows. You need to find the top 10
-- customers by spend in the last 30 days, joining customers
-- and orders. Write the most optimized version of this query
-- possible. Consider: which columns need indexes, can you
-- limit early, what's the join order. Write your reasoning
-- as comments.
-- Index needed for date filter and join
-- CREATE INDEX idx_orders_date ON orders(order_date);
-- CREATE INDEX idx_orders_customer ON orders(customer_id);

SELECT c.customer_name, SUM(o.total_amount) AS total_spent
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC
LIMIT 10;


-- C3. Explain why this index would NOT help this query:
-- Index: CREATE INDEX idx_status ON orders(status);
-- Query: SELECT * FROM orders WHERE status = 'delivered';
-- (Hint: think about cardinality and what percentage
-- of rows match. Then write an alternative optimization.)
-- Not work because of low cardinality which means the column status has very low unique values 
-- high matching percentage 
CREATE INDEX active_order_indx ON orders(status)
WHERE status != 'delivered';
