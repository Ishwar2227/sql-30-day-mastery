-- I1. Create a view called 'customer_order_summary' that joins
-- customers and orders and shows:
-- customer_name, city, order_count, total_spent.
-- Use GROUP BY inside the view.
-- Then query it for customers with total_spent > 500.
CREATE VIEW customer_order_summary AS
SELECT c.customer_name, c.city, COUNT(o.order_id) AS order_count, 
SUM(o.total_amount) AS total_spent
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.city

SELECT customer_name FROM customer_order_summary
WHERE total_spent > 500;


-- I2. Create a materialized view called 'city_revenue_mv' that shows
-- city and total_revenue per city (JOIN customers + orders).
-- Then SELECT from it.
-- Then run REFRESH MATERIALIZED VIEW on it.
CREATE MATERIALIZED VIEW city_revenue_mv AS
SELECT c.city,SUM(o.total_amount) AS total_revenue 
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY city;

SELECT * FROM city_revenue_mv;


-- I3. Write a transaction that:
-- - Inserts a new customer
-- - Inserts an order for that customer
-- - COMMITs both together
-- Verify both records exist after commit.
BEGIN;
INSERT INTO customers (
		customer_name,city,age,email,signup_date,is_active
)
VALUES('Ishwar Soma','Solapur',20,'ishwar@gmail.com',CURRENT_DATE,TRUE);
INSERT INTO orders (
    customer_id,order_date,total_amount,status
)
VALUES (
    currval('customers_customer_id_seq'),
    CURRENT_DATE,
    850.00,
    'processing'
);
COMMIT;

SELECT * FROM customers 
WHERE customer_name = 'Ishwar Soma';

SELECT * FROM orders 
WHERE customer_id = (
	SELECT customer_id 
	FROM customers 
	WHERE customer_name = 'Ishwar Soma'
);


-- I4. Create a stored procedure called 'customer_city_update'
-- that takes customer_id and new_city as parameters
-- and updates the customer's city.
-- CALL it to move customer_id 1 to 'Bangalore'.
-- Then SELECT to verify.
CREATE OR REPLACE PROCEDURE customer_city_update(
		p_customer_id INT,
		p_new_city VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
		UPDATE customers 
		SET city = p_new_city
		WHERE customer_id = p_customer_id;
		
		RAISE NOTICE 'customer % moved to % ',
		p_customer_id,
		p_new_city;
		
END;
$$;

CALL customer_city_update(1,'Solapur');

SELECT customer_id , customer_name , city 
FROM customers
WHERE customer_id = 1;


-- I5. Drop the views you created and recreate them using
-- CREATE OR REPLACE VIEW syntax.
-- Explain in a comment why OR REPLACE is better than DROP + CREATE.
DROP VIEW IF EXISTS customer_order_summary;
DROP VIEW IF EXISTS city_revenue_mv;

CREATE OR REPLACE VIEW active_customer_view AS 
SELECT c.customer_name , c.city, COUNT(o.order_id) AS order_count,
SUM(o.total_amount) AS total_spent
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id 
GROUP BY c.customer_id, c.customer_name , c.city;

-- CREATE OR REPLACE VIEW updates the existing view definition 
--without deleting the view itself.
-- DROP + CREATE can break queries, applications, or permissions temporarily.