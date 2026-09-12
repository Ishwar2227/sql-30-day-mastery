-- Mini Project — "Reporting Layer Build"
-- Your manager says:

-- "We need a clean reporting layer so the business team can query data 
--without touching raw tables. Build views for our three most common reports, 
--wrap our order update logic in a stored procedure, and make sure everything is transactionally safe."

-- Requirements:
-- View 1: active_customer_report — active customers with city, email, signup_era (Early Adopter/Recent from Day 7)
-- View 2: order_performance_report — all orders with customer_name, city, total_amount, status, and order_size (Small/Medium/Large from Day 7)
-- View 3: customer_value_report — customer_name, total_spent, spend_rank, value_segment (reuse Day 8 logic)
-- Stored Procedure: update_order_status(order_id INT, new_status VARCHAR) — updates order status, raises a notice confirming the change
-- Transaction: Insert one new test customer and one test order in a single transaction. Commit it. Then SELECT to verify.
-- 3-line comment on each view explaining its business purpose.

--Part 1 
SELECT COUNT(*) AS total_records,
		(
		SELECT COUNT(*) 
		FROM (
				SELECT email 
				FROM customers
				GROUP BY email 
				HAVING COUNT(*) > 1
		) duplicates
		) AS duplicate_count
		COUNT( 
			CASE WHEN email IS NULL THEN 1 END 
			) AS missing_email_count ,
		COUNT(
			CASE WHEN city <> INITCAP(city) THEN 1 END 
		) AS dirty_city_count
FROM customers;

--Part 2 
UPDATE customers
SET customer_name = TRIM(customer_name);

UPDATE customers
SET city = INITCAP(LOWER(city));

UPDATE customers
SET email = LOWER(email);

-- Business Purpose:
-- Provides cleaned customer data for the Data Science team.
-- Includes only complete customer records with standardized text fields.
CREATE OR REPLACE VIEW cleaned_customer_view AS
SELECT
    customer_id,
    TRIM(customer_name) AS customer_name,
    INITCAP(LOWER(city)) AS city,
    LOWER(email) AS email,
    age,
    signup_date
FROM customers
WHERE email IS NOT NULL
AND age IS NOT NULL
ORDER BY signup_date DESC;		
