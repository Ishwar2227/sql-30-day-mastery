-- I1. Find the total revenue generated per order status
-- (delivered, cancelled, etc.)
SELECT status, SUM(total_amount) AS total_revenue
FROM orders
GROUP BY status;


-- I2. Find the number of customers per city,
-- but only show cities that have more than 1 customer.
SELECT city,COUNT(*) 
FROM customers 
GROUP BY city
HAVING COUNT(*) > 1;


-- I3. Find the average age of customers grouped by city,
-- ordered by average age descending.
SELECT city, AVG(age) AS avg_age
FROM customers 
GROUP BY city 
ORDER BY avg_age DESC;


-- I4. Find the total amount spent per customer (using customer_id),
-- show only customers who spent more than 500 in total.
-- Order by total spent descending.
SELECT customer_id , SUM(total_amount) AS total_spent
FROM orders 
GROUP BY customer_id
HAVING SUM(total_amount) > 500
ORDER BY total_spent DESC;


-- I5. Count how many customers have a NULL email vs non-NULL email.
-- Hint: GROUP BY (email IS NULL)
SELECT COUNT(email), COUNT(email IS NULL)
FROM customers
GROUP BY (email IS NULL);
