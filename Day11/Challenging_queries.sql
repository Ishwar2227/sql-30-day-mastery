-- C1. Identify and remove duplicate customers keeping only
-- the one with the lowest customer_id.
-- Use ROW_NUMBER() inside a CTE, then DELETE.
-- Show the records that would be deleted BEFORE deleting.
-- (Run the SELECT first, verify, then run DELETE.)
WITH ranked AS ( 
	SELECT *,
	ROW_NUMBER() OVER(
			PARTITION BY customer_name , city
			ORDER BY customer_id 
	) AS rn
	FROM customers
)

DELETE FROM customers 
WHERE customer_id IN (
	SELECT customer_id FROM ranked
	WHERE rn > 1
);


-- C2. Write a full data quality report as a single query showing:
-- - total_records
-- - duplicate_names (customers sharing a name with someone)
-- - missing_email_pct (percentage with no email)
-- - dirty_city_pct (percentage where city != INITCAP(city))
-- - outlier_ages (count of age outliers beyond 2 std devs)
-- All in one row. This is a real data audit query.
SELECT COUNT(*) AS total_records ,
( 
SELECT COUNT(*) 
FROM customers 
WHERE customer_name IN ( 
	SELECT customer_name 
	FROM customers 
	GROUP BY customer_name 
	HAVING COUNT(*) > 1
)
) AS duplicate_names ,
ROUND(
COUNT( 
	CASE
		WHEN email IS NULL THEN 1 
		END 
	) * 100.0 / COUNT(*) , 2) AS missing_email_pct,
	
ROUND(
COUNT(
	CASE
		WHEN city <> INITCAP(city) 
		THEN 1 
		END ) *100.0 / COUNT(*),2) AS dirty_city_pct,
		
COUNT(
CASE
	WHEN age > 
	( SELECT AVG(age) + 2*STDDEV(age)
	FROM customers 
  )
THEN 1 
END ) AS outlier_ages
FROM customers;


-- C3. Create a cleaned_customers view that applies all
-- cleaning transformations without modifying the original table:
-- - TRIM on customer_name
-- - INITCAP on city
-- - LOWER on email
-- - COALESCE(email, 'unknown@placeholder.com')
-- - A record_completeness column: 'Complete' or 'Incomplete'
-- based on whether email AND age are both present
-- This is a production pattern — transform at query time,
-- keep raw data untouched.
CREATE OR REPLACE VIEW cleaned_customer AS
SELECT 
customer_id ,
	TRIM(customer_name) AS customer_name,
	
	INITCAP(LOWER(city)) AS city,
	
	COALESCE(
		LOWER(email),'unknown@placeholder.com') AS email,
		age,
	CASE
		WHEN email IS NOT NULL AND age IS NOT NULL THEN 'Complete'
		ELSE 'Incomplete'
	END AS record_completeness 
	FROM customers;
