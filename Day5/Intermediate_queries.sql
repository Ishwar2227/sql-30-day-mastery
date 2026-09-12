-- I1. Find the total revenue per product category.
-- Show category and category_revenue.
-- Use order_items + products, GROUP BY category.
SELECT p.category, SUM(oi.unit_price * oi.quantity) AS category_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id 
GROUP BY p.category;

-- I2. Find customers who bought Electronics.
-- Show customer_name and product_name.
-- No duplicates — use DISTINCT.
SELECT DISTINCT c.customer_name , p.product_name 
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id
WHERE p.category = 'Electronics';

-- I3. Find the most expensive product that was actually ordered.
-- Show product_name and unit_price.
-- Use order_items + products.
SELECT p.product_name, oi.unit_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
ORDER BY oi.unit_price DESC
LIMIT 1;



-- I4. Find customers who spent more than the average order amount.
-- Show customer_name and total_amount.
-- Use a subquery for the average:
-- WHERE o.total_amount > (SELECT AVG(total_amount) FROM orders)
SELECT c.customer_name , o.total_amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.total_amount > (SELECT AVG(total_amount) FROM orders);


-- I5. Show customer_name, city, product_name, and total_amount
-- for customers from Pune only.
-- Use all 4 tables + WHERE filter.
SELECT c.customer_name , c.city, p.product_name , o.total_amount
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id 
WHERE c.city = 'Pune'; 