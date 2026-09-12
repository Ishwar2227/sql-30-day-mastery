-- I1. Find all active customers who have an email,
-- are from Mumbai or Pune, and are between 25 and 40 years old.
-- Alias age as 'customer_age'
SELECT 
    customer_name, 
    email, 
    age AS customer_age
FROM customers
WHERE is_active = TRUE
AND email IS NOT NULL
AND city IN ('Pune', 'Mumbai')
AND age BETWEEN 25 AND 40;


-- I2. Show unique statuses that exist in the orders table.
SELECT DISTINCT status FROM orders;


-- I3. Show customer_name and a computed column called 'has_email'
-- that shows TRUE if email exists, FALSE if it is NULL.
SELECT 
    customer_name,
    (email IS NOT NULL) AS has_email
FROM customers;


-- I4. Find all orders where status is NOT IN ('cancelled', 'processing')
-- and total_amount > 300. Alias total_amount as 'order_value'.
SELECT 
    order_id, 
    total_amount AS order_value
FROM orders
WHERE status NOT IN ('cancelled', 'processing')
AND total_amount > 300;


-- I5. Find customers where city is NOT NULL and email IS NULL —
-- these are incomplete profiles. Alias customer_name as 'incomplete_profile'.
SELECT customer_name AS incomplete_profile FROM customers 
WHERE city IS NOT NULL
AND email is NULL;
