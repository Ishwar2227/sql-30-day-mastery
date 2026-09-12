-- You're a data analyst. Your manager asks:
-- "Give me a quick summary of our order data. I want to know how each order status is performing — how many orders, what's the total revenue, and what's the average order value per status. Only show me statuses that have more than 1 order. Sort by total revenue highest first."

-- Write one query. Requirements:
-- - Columns: `status`, `order_count`, `total_revenue`, `avg_order_value`
-- - Proper aliases on all computed columns
-- - HAVING to filter groups
-- - ORDER BY total revenue descending
-- - 3-line comment above explaining what the query does

-- -- summary of orders grouped by status 
-- -- Includes count, total revenue, and average order value per status 
-- -- only shows status is more that 1 order, sorted by highest revenue 

SELECT 
	status,
	COUNT(*) AS order_count,
	SUM(total_amount) AS total_revenue,
	AVG(total_amount) AS avg_order_value
FROM orders
GROUP BY status
HAVING COUNT(*) > 1
ORDER BY total_revenue DESC;
