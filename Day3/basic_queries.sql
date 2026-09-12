-- B1. Count the total number of customers in the table.
SELECT COUNT(*) 
FROM customers;


-- B2. Find the total revenue (sum of total_amount) from all orders.
SELECT SUM(total_amount) AS total_revenue
FROM orders;


-- B3. Find the average order value across all orders.
SELECT AVG(total_amount) AS avg_order_value
FROM orders;


-- B4. Count how many customers exist per city.
SELECT city , COUNT(*)
FROM customers
GROUP BY city;


-- B5. Find the most expensive order (maximum total_amount).
SELECT total_amount , MAX(total_amount)
FROM orders;
