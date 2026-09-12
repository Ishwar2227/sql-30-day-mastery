Your manager asks:
"I need to identify our most valuable customers. Show me customers who have spent above the average customer spend, what city they're from, how many orders they've placed, and their total spend. Also flag if they have any delivered orders. Sort by total spend descending."*

- Columns: `customer_name`, `city`, `order_count`, `total_spent`, `has_delivered_order` (TRUE/FALSE)
- Use a subquery to filter above-average spenders
- Use EXISTS for the delivered order flag
- 3-line comment explaining business purpose
- ORDER BY total_spent DESC

-- Identify high-value customers based on total spending behavior
-- Includes order count, total spend, and delivery activity flag
-- Filters customers who spend above average and ranks them by spend
SELECT 
    c.customer_name,
    c.city,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_amount) AS total_spent,
    EXISTS (
        SELECT 1
        FROM orders o2
        WHERE o2.customer_id = c.customer_id
        AND o2.status = 'delivered'
    ) AS has_delivered_order
FROM customers c
JOIN orders o 
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.city
HAVING SUM(o.total_amount) > (
    SELECT AVG(customer_total)
    FROM (
        SELECT SUM(total_amount) AS customer_total
        FROM orders
        GROUP BY customer_id
    ) sub
)
ORDER BY total_spent DESC;
