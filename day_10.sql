-- ## Mini Project — "Reporting Layer Build"
-- > "We need a clean reporting layer so the business team can query 
--data without touching raw tables. Build views for our three most common 
--reports, wrap our order update logic in a stored procedure, and make sure 
--everything is transactionally safe."*
-- > 

-- Requirements:
-- View 1: `active_customer_report` — active customers with city, email, signup_era (Early Adopter/Recent from Day 7)

-- View 2: `order_performance_report` — all orders with customer_name, city, total_amount, status, and order_size (Small/Medium/Large from Day 7)

-- View 3: `customer_value_report` — customer_name, total_spent, spend_rank, value_segment (reuse Day 8 logic)

-- Stored Procedure: `update_order_status(order_id INT, new_status VARCHAR)` — updates order status, raises a notice confirming the change

-- Transaction: Insert one new test customer and one test order in a single transaction. Commit it. Then SELECT to verify.




-- Business Purpose:
-- Provides a list of all active customers for reporting.
-- Includes customer location, email, and signup era.
CREATE OR REPLACE VIEW active_customer_report AS
SELECT
    customer_name,
    city,
    email,

    CASE
        WHEN signup_date < '2024-01-01'
            THEN 'Early Adopter'
        ELSE 'Recent'
    END AS signup_era
FROM customers
WHERE is_active = TRUE;

-- Shows all orders with customer details and order size classification
-- Used by business team to track order performance by size category
-- Joins customers and orders to provide full order context
CREATE VIEW order_performance_report AS
SELECT c.customer_name, c.city, o.total_amount, status, 
CASE
    WHEN total_amount < 300 THEN 'Small'
    WHEN total_amount <= 700 THEN 'Medium'
    ELSE 'Large'
END AS order_size
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id;

-- Business Purpose:
-- Summarizes customer spending and ranks customers by total spend.
-- Helps identify High, Mid, and Low Value customers.
CREATE VIEW customer_value_report AS
SELECT  c.customer_name,
		SUM(o.total_amount) AS total_spent,
		DENSE_RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS spend_rank,
		CASE 
				WHEN SUM(o.total_amount) >= 1000 THEN 'High value'
				WHEN SUM(o.total_amount) >= 500 THEN 'Mid value'
				ELSE 'Low value'
		END AS value_segment
FROM customers c JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id ,c.customer_name;


CREATE OR REPLACE PROCEDURE update_order_status(p_order_id INT, p_new_status VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN 
		UPDATE orders 
		SET status = p_new_status
		WHERE order_id = p_order_id;
		
		RAISE NOTICE 'order % update to %' ,
		p_order_id,
		p_new_status;
END;
$$;

CALL update_order_status(3,'delivered');

BEGIN;
INSERT INTO customers(customer_name, city, age,email, signup_date, is_active)
VALUES('test customer' , 'Pune', 22, 'test@gmail.com', CURRENT_DATE, TRUE );

INSERT INTO orders(customer_id , order_date, total_amount, status)
VALUES(currval('customers_customer_id_seq'),CURRENT_DATE, 500, 'processing');
COMMIT;

SELECT * FROM orders 
WHERE customer_id = (SELECT customer_id from customers 
WHERE customer_name = 'test customer');
