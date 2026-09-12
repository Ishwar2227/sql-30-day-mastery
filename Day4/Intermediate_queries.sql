-- I1. Find all customers who have NOT placed any orders.
-- Show their customer_name and city.
-- Hint: LEFT JOIN + WHERE o.order_id IS NULL
SELECT c.customer_name, c.city
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;


-- I2. Show customer_name, city, order_date, total_amount, and status
-- for all delivered orders only.
-- Use INNER JOIN + WHERE.
SELECT c.customer_name, c.city, o.order_date, o.total_amount, o.status
FROM customers c
INNER JOIN orders o
ON c.customer_id = o.customer_id
WHERE o.status = 'delivered';


-- I3. Find the average order value per city.
-- You need to JOIN customers and orders to get city onto the orders.
-- Show city and avg_order_value, ordered by avg_order_value DESC.
SELECT c.city, AVG(o.total_amount) AS avg_order_value
FROM customers c
INNER JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.city
ORDER BY avg_order_value DESC;


-- I4. Find customers who have placed more than 1 order.
-- Show customer_name and order_count.
Use JOIN + GROUP BY + HAVING.
SELECT c.customer_name , COUNT(o.order_id) AS order_count 
FROM customers c 
JOIN orders o 
ON c.customer_id = o.customer_id 
GROUP BY c.customer_name
HAVING COUNT(o.order_id) > 1;


-- I5. Show each customer's name and their most recent order date.
-- Show customer_name and last_order_date.
-- Use JOIN + GROUP BY + MAX.
SELECT c.customer_name , MAX(o.order_date) AS last_order_date 
FROM customers c
JOIN orders o 
ON c.customer_id = o.customer_id 
GROUP BY c.customer_id , c.customer_name;
