-- C1. Create a view that shows each customer's name,
-- their total spend, their spend rank using DENSE_RANK,
-- and their value segment (High/Mid/Low).
-- This view combines your Day 8 mini project logic.
-- Then query it to show only High Value customers.
CREATE VIEW customers_details AS
SELECT  c.customer_name,
		SUM(o.total_amount) AS total_spent,
		DENSE_RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS spend_rank,
		CASE 
				WHEN SUM(o.total_amount) >= 1000 THEN 'High value'
				WHEN SUM(o.total_amount) >= 500 THEN 'Mid value'
				ELSE 'Low value'
		END AS value_segment
FROM customers c JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name;

SELECT * FROM customers_details;


-- C2. Write a stored procedure called 'process_new_order'
-- that takes customer_id, total_amount, and status as parameters.
-- Inside the procedure:
-- - INSERT the new order with today's date
-- - If total_amount > 1000, also update the customer's
-- is_active to TRUE (assume high spenders are always active)
-- - Use a transaction inside the procedure
-- CALL it with a test order and verify both changes.
CREATE OR REPLACE PROCEDURE process_new_order(
		customer_id_param NUMERIC,
		total_amount_param NUMERIC,
		status_param VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN 
	 INSERT INTO orders(customer_id, total_amount, status, order_date)
	 VALUES(customer_id_param, total_amount_param, status_param, CURRENT_DATE);
	 
	 IF total_amount_param > 1000 THEN 
			 UPDATE customers 
			 SET is_active = TRUE 
			 WHERE customer_id = customer_id_param; 
	END IF;
	
	COMMIT;
END;
$$;


-- C3. Create a materialized view for the monthly revenue report
-- from Day 9 C2. Then write a query that compares each month's
-- revenue to the previous month using LAG on the materialized view.
-- Show month, monthly_revenue, prev_month_revenue, growth.
CREATE MATERIALIZED VIEW monthly_revenue_mv AS
SELECT
    DATE_TRUNC('month', order_date) AS month,
    SUM(total_amount) AS monthly_revenue

FROM orders

GROUP BY DATE_TRUNC('month', order_date)

ORDER BY month;

SELECT
    month,
    monthly_revenue,

    LAG(monthly_revenue)
    OVER (ORDER BY month) AS prev_month_revenue,

    monthly_revenue -
    LAG(monthly_revenue)
    OVER (ORDER BY month) AS growth

FROM monthly_revenue_mv;
