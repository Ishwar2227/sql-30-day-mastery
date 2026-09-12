-- I1. Find customers whose total spending across all orders
-- is greater than the average spending per customer.
-- Show customer_name and total_spent.
-- Hint: you need a subquery that calculates average of
-- per-customer totals — similar to C3 from Day 5.
SELECT c.customer_name, SUM(o.total_amount) AS total_spent 
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id 
GROUP BY c.customer_name 
HAVING SUM(o.total_amount) > (SELECT AVG(customer_total) FROM (SELECT SUM(total_amount) AS customer_total
FROM orders 
GROUP BY customer_id 
) sub);


-- I2. Find products that have NEVER been ordered.
-- Use NOT IN with a subquery.
-- Show product_name.
SELECT product_name 
FROM products p
WHERE product_id NOT IN (SELECT product_id FROM 
order_items oi WHERE oi.product_id = p.product_id);


-- I3. Find orders placed by customers from Pune.
-- Use a subquery with IN — do NOT use JOIN.
-- Show order_id, total_amount, status.
SELECT order_id , total_amount , status 
FROM orders 
WHERE customer_id IN (SELECT customer_id FROM customers WHERE city = 'Pune');


-- I4. Find the customer who placed the most recent order.
-- Show customer_name and order_date.
-- Use a subquery for the max date.
SELECT c.customer_name, o.order_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date = (SELECT MAX(order_date) FROM orders);


-- I5. For each customer, show their name and whether they have
-- any delivered orders. Show customer_name and has_delivered_order
-- as TRUE/FALSE. Use EXISTS.
SELECT c.customer_name , 
EXISTS(SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id 
AND o.status = 'delivered') AS has_delivered_order 
FROM customers c;