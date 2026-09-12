-- B1. Select all unique cities from the customers table.
SELECT DISTINCT city 
FROM customers;


-- B2. Select customer_name aliased as 'name' and city aliased as 'location'
-- from customers.
SELECT customer_name AS name, city AS location
FROM customers;


-- B3. Find all customers where email IS NOT NULL.
SELECT customer_name, email
FROM customers
WHERE email IS NOT NULL;


-- B4. Show customer_name and email — where email is NULL,
-- display 'No email' instead. (use COALESCE)
SELECT customer_name, COALESCE(email, 'No email') AS email
FROM customers;


-- B5. Find all customers NOT from Pune or Bangalore.
SELECT customer_name
FROM customers
WHERE city NOT IN ('Pune', 'Bangalore')
AND city IS NOT NULL;


