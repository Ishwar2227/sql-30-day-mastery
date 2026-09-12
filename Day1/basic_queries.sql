-- B1. Select only the customer_name and city columns from the customers table.
SELECT customer_name, city 
FROM customer_table;


-- B2. Find all customers from the city 'Pune'.
SELECT * 
FROM customer_table 
WHERE city = 'Pune';

-- B3. Find all orders with a total_amount greater than 500.
SELECT * 
FROM orders 
WHERE total_amount > 500;


-- B4. Get the 10 most recent orders (use order_date, newest first).
SELECT * 
FROM orders 
ORDER BY order_date DESC 
LIMIT 10;


-- B5. Find all customers whose email contains 'gmail'.
SELECT * 
FROM customer_table 
WHERE email ILIKE '%gmail%';
