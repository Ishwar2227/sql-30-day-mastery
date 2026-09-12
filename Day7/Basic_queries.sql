-- B1. Add a 'region' column to customers using CASE:
-- Mumbai, Pune → 'West'
-- Delhi → 'North'
-- Bangalore → 'South'
-- Anything else → 'Other'
-- Show customer_name, city, region.
SELECT customer_name ,
	CASE city
			WHEN 'Mumbai' THEN 'West'
			WHEN 'Pune' THEN 'West'
			WHEN 'Delhi' THEN 'North'
			WHEN 'Bangalore' THEN 'South'
			ELSE 'Other'
	END AS region 
FROM customers;


-- B2. Categorize customers by age:
-- Under 25 → 'Young'
-- 25-35 → 'Mid'
-- Over 35 → 'Senior'
-- Show customer_name, age, age_group.
SELECT customer_name ,
	CASE 
			WHEN age < 25 THEN 'Young'
			WHEN age BETWEEN 25 AND 35 THEN 'Mid'
			WHEN age > 35 THEN 'Senior'
			ELSE 'Error'
	END AS age_group 
FROM customers;


-- B3. Add a 'order_size' column to orders:
-- total_amount < 300 → 'Small'
-- 300-700 → 'Medium'
-- Above 700 → 'Large'
-- Show order_id, total_amount, order_size.
SELECT order_id ,
		CASE 
			WHEN total_amount < 300 THEN 'Small'
			WHEN total_amount BETWEEN 300 AND 700 THEN 'Medium'
			WHEN total_amount > 700 THEN 'Large'
			ELSE 'Unknown'
		END AS order_size 
FROM orders;


-- B4. Show customer_name and a column called 'contact_status':
-- email IS NOT NULL → 'Reachable'
-- email IS NULL → 'Unreachable'
-- (You solved this in Day 2 C1 with COALESCE — now do it properly with CASE)
SELECT customer_name ,
	CASE 
		WHEN email IS NOT NULL THEN 'Reachable'
		ELSE 'Unreachable'
	END AS contact_status 
FROM customers;

-- B5. Show order_id, status, and a column called 'is_complete':
-- 'delivered' → TRUE
-- anything else → FALSE
SELECT order_id ,
	CASE status 
		WHEN 'delivered' THEN TRUE 
		ELSE FALSE
	END AS is_complete 
FROM orders;









