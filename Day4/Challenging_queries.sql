-- C1. Find the customer who has spent the most in total.
-- Show customer_name and total_spent.
-- Return only the top 1.
SELECT c.customer_name, SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_name
ORDER BY total_spent DESC
LIMIT 1;


-- C2. Find cities where the total revenue from orders exceeds 500.
-- Show city and city_revenue.
-- You'll need JOIN + GROUP BY + HAVING.
SELECT c.city, SUM(o.total_amount) AS city_revenue
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.city
HAVING SUM(o.total_amount) > 500;

-- C3. Write a query that shows ALL customers.
-- For customers with orders: show their total_spent.
-- For customers without orders: show 0 (not NULL).
-- Hint: LEFT JOIN + COALESCE.
SELECT 
    c.customer_name,
    COALESCE(SUM(o.total_amount), 0) AS total_spent
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_name;



