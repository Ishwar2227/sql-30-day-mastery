-- Your manager asks:
-- "I need a complete customer activity report. Show me every customer, their city, how many orders they've placed, and their total spend. If they've never ordered, show 0 for both. Sort by total spend highest first."*

-- Requirements:
-- - Columns: `customer_name`, `city`, `order_count`, `total_spent`
-- - Customers with no orders must appear with 0s — not NULL, not excluded
-- - Proper aliases
-- - 3-line comment
-- - ORDER BY total_spent DESC

-- -- Customer activity report with order count and total spending
-- -- Includes customers with no orders using LEFT JOIN
-- -- Replaces NULL values with 0 and sorts by highest spending

SELECT 
    c.customer_name,
    c.city,
    COUNT(o.order_id) AS order_count,
    COALESCE(SUM(o.total_amount), 0) AS total_spent
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_name, c.city
ORDER BY total_spent DESC;
