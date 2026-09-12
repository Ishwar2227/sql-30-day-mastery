-- B1. Join all four tables (customers, orders, order_items, products).
-- Show customer_name, product_name, and quantity.
SELECT c.customer_name, p.product_name, oi.quantity
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id;


-- B2. Show customer_name, product_name, and unit_price
-- for all orders. Use all 4 tables.
SELECT c.customer_name , p.product_name, oi.unit_price
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id;


-- B3. Find all products purchased in 'delivered' orders.
-- Show customer_name, product_name, status.
SELECT c.customer_name , p.product_name , o.status
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'delivered';


-- B4. Show the total quantity of each product sold.
-- Show product_name and total_quantity.
-- Use order_items + products.
SELECT p.product_name, SUM(oi.quantity) AS total_quantity
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name;


-- B5. Show customer_name and the category of products they bought.
-- Use all 4 tables.
SELECT c.customer_name , p.category
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id;














