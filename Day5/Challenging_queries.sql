-- C1. Find the top-selling product category by total revenue.
-- Show category and total_revenue.
-- Return only the #1 category.
SELECT p.category, SUM(oi.unit_price * oi.quantity) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC
LIMIT 1;


-- C2. Find customers who have ordered products from more than
-- one category. Show customer_name and category_count.
-- Hint: COUNT(DISTINCT p.category)
SELECT c.customer_name, COUNT(DISTINCT p.category) AS category_count
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id 
GROUP BY c.customer_name
HAVING COUNT(DISTINCT p.category) > 1;


-- C3. For each customer show their name, total amount spent,
-- and whether they are above or below the average customer spend.
-- Label it 'Above Average' or 'Below Average'.
-- Use a subquery inside CASE for the average.
SELECT 
    c.customer_name,
    SUM(o.total_amount) AS total_spent,
    CASE 
        WHEN SUM(o.total_amount) > (SELECT AVG(total_spent) FROM (SELECT SUM(total_amount) AS total_spent
                FROM orders
                GROUP BY customer_id) sub)
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS spend_category
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name;