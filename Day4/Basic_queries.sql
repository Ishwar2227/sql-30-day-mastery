-- B1. Write an INNER JOIN between customers and orders.
-- Show customer_name and total_amount.
-- Use table aliases c and o.
SELECT 
	c.customer_name , o.total_amount
FROM customers c
INNER JOIN orders o 
ON c.customer_id = o.customer_id;

-- B2. Show all customers and their orders using LEFT JOIN.
-- Include customers who have no orders.
Show customer_name, order_id, total_amount.
SELECT c.customer_name , o.order_id, o.total_amount
FROM customers c 
LEFT JOIN orders o
ON c.customer_id = o.customer_id;


-- B3. Using INNER JOIN, show customer_name, city, and order_date
-- for all customers who have placed orders.
SELECT c.customer_name , c.city, o.order_date
FROM customers c 
INNER JOIN orders o
ON c.customer_id = o.customer_id;

-- B4. Count the total number of orders each customer has placed.
-- Show customer_name and order_count.
-- Use INNER JOIN + GROUP BY.
SELECT c.customer_name, COUNT(o.order_id) AS total_orders
FROM customers c
INNER JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_name;


-- B5. Find the total amount spent by each customer.
-- Show customer_name and total_spent.
-- Use INNER JOIN + GROUP BY + ORDER BY total_spent DESC.
SELECT c.customer_name, SUM(o.total_amount) AS total_spent
FROM customers c
INNER JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_name
ORDER BY total_spent DESC;




