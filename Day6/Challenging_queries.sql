-- C1. Find customers who have ordered ALL categories of products.
-- (Customers whose distinct category count equals the total
-- number of categories in the products table.)
-- Show customer_name.
-- Step 1: how many total categories exist?
SELECT COUNT(DISTINCT category) FROM products;  -- gives you 3

-- Step 2: which customers have category count = 3?
SELECT c.customer_name
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.customer_name
HAVING COUNT(DISTINCT p.category) = (SELECT COUNT(DISTINCT category) FROM products);

-- C2. Find the second highest total_amount in the orders table.
-- Show just the amount.
-- Do it WITHOUT using LIMIT/OFFSET.
-- Hint: find the maximum value that is less than the maximum.
SELECT MAX(total_amount)
FROM orders
WHERE total_amount < (SELECT MAX(total_amount) FROM orders);


-- C3. For each city, find the customer with the highest total spend.
-- Show city, customer_name, total_spent.
-- This requires a subquery in WHERE or HAVING.
SELECT c.city,c.customer_name, SUM(o.total_amount) AS total_apent 
FROM customers c  
JOIN orders o ON c.customer_id = o.customer_id 
GROUP BY c.city, c.customer_name 
	HAVING SUM(o.total_amount) = (SELECT MAX(city_totals.total) FROM (
	SELECT SUM(o2.total_amount ) AS total
	FROM customers c2
	JOIN orders o2 ON c2.customer_id = o2.customer_id 
	WHERE c2.city = c.city
	GROUP BY c2.customer_id 
) city_totals );