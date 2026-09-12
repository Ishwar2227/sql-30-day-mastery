-- B1. Find all customers who have placed at least one order.
-- Use a subquery with IN.
-- (Don't use JOIN)
SELECT customer_name 
FROM customers 
WHERE customer_id IN (SELECT customer_id FROM orders);


-- B2. Find all customers who have NEVER placed an order.
-- Use NOT IN with a subquery.
SELECT customer_name 
FROM customers 
WHERE customer_id NOT IN (SELECT customer_id FROM orders);


-- B3. Find all orders where total_amount is above
-- the average total_amount. Show order_id and total_amount.
SELECT order_id , total_amount 
FROM orders 
WHERE total_amount > (SELECT AVG(total_amount) FROM orders);

B4. Find products that have been ordered at least once.
Use EXISTS.
Show product_name.

SELECT product_name 
FROM products p
WHERE EXISTS(
		SELECT 1 
		FROM order_items oi 
		WHERE oi.product_id = p.product_id
		);


-- B5. Show each customer's name and their total number of orders
-- as a correlated subquery in SELECT.
-- Show customer_name and order_count.
SELECT customer_name ,
			(SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) AS order_count
FROM customers c;










