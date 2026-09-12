-- I1. Find duplicate customers — same customer_name and same city.
-- Show customer_name, city, and how many times they appear.
-- Only show groups with more than 1 occurrence.
SELECT customer_name , city, COUNT(*) AS occurrences
FROM customers 
GROUP BY customer_name , city 
HAVING COUNT(*) > 1;


-- I2. Write a cleaning UPDATE that:
-- - Trims whitespace from customer_name
-- - Converts city to title case (INITCAP)
-- - Converts email to lowercase
-- Do all three in one UPDATE statement per table.
-- (Write three separate UPDATE statements.)
UPDATE customers 
SET customer_name = TRIM(customer_name);

UPDATE customers 
SET city = INITCAP(LOWER(city));

UPDATE customers 
SET email = LOWER(email);


-- I3. Find customers whose age is a statistical outlier —
-- more than 2 standard deviations from the mean age.
-- Show customer_name and age.
SELECT customer_name, age 
FROM customers 
WHERE age > (
		SELECT AVG(age) + 2 * STDDEV(age)
		FROM customers 
);


-- I4. Write a data completeness report showing:
-- - total_customers
-- - has_email (count)
-- - has_age (count)
-- - complete_records (both email AND age present)
-- All in one query, no GROUP BY.
SELECT COUNT(*) AS total_customers,
COUNT(email) AS has_email,
COUNT(age) AS has_age,
COUNT(
	CASE 
		WHEN email IS NOT NULL 
		AND age IS NOT NULL THEN 1
	END 
	) AS complete_records
FROM customers;		


-- I5. Show customer_name, customer_id as VARCHAR,
-- and a combined column called customer_code:
-- format: 'CUST-' || customer_id || '-' || UPPER(LEFT(city, 3))
-- Example: 'CUST-1-PUN' for customer_id 1 from Pune.
SELECT
    customer_name,
    CAST(customer_id AS VARCHAR),
    'CUST-' || customer_id || '-' || UPPER(LEFT(city, 3)) AS customer_code
FROM customers;

