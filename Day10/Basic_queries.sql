-- B1. Create a view called 'pune_customers' that shows
-- customer_id, customer_name, email for all customers from Pune.
-- Then SELECT all columns from it.
CREATE VIEW pune_customers AS 
SELECT customer_id , customer_name , email 
FROM customers 
WHERE city = 'Pune';

SELECT * FROM pune_customers;


-- B2. Create a view called 'delivered_orders' that shows
-- order_id, customer_id, total_amount for delivered orders only.
-- Query it to find orders above 500.
CREATE VIEW delivered_orders1 AS 
SELECT order_id , customer_id , total_amount 
FROM orders
WHERE status = 'delivered' AND total_amount > 500;

SELECT * FROM delivered_orders1;


-- B3. Write a transaction that updates two orders to 'shipped' status.
-- Use BEGIN and COMMIT correctly.
BEGIN;
UPDATE orders SET status = 'shipped' WHERE order_id = 1;
UPDATE orders SET status = 'shipped' WHERE order_id = 2;
COMMIT;


-- B4. Write a transaction that intentionally uses ROLLBACK.
-- Update an order status, then ROLLBACK.
-- Verify the change was undone by SELECTing the order.
BEGIN;

UPDATE orders SET status = 'shipped' WHERE order_id = 1;

ROLLBACK;

SELECT status FROM orders WHERE order_id = 1;


-- B5. Create a simple stored procedure called 'mark_delivered'
-- that takes an order_id parameter and sets its status to 'delivered'.
-- Then CALL it with order_id = 3.
CREATE OR REPLACE PROCEDURE mark_delivered(order_id_param INT)
LANGUAGE plpgsql
AS $$
BEGIN 
		UPDATE orders 
		SET status = 'delivered'
		WHERE order_id = order_id_param;
END;
$$;

CALL mark_delivered(3);










