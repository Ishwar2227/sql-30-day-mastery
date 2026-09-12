-- B1. Write a CTE called 'customer_spend' that calculates
-- total_spent per customer. Then SELECT from it
-- showing customer_name and total_spent.
WITH customer_spend AS (
		SELECT c.customer_name , SUM(total_amount) AS total_spent 
		FROM customers c 
		JOIN orders o ON c.customer_id = o.customer_id 
		GROUP BY c.customer_id, c.customer_name
)
SELECT customer_name , total_spent 
FROM customer_spend;

-- B2. Add a ROW_NUMBER to all orders ordered by total_amount DESC.
-- Show order_id, total_amount, row_num.
SELECT order_id , total_amount,
		ROW_NUMBER() OVER (ORDER BY total_amount DESC) AS row_num
FROM orders;


-- B3. Show each customer's name, city, age, and the average age
-- of customers in their city using a window function.
-- Show avg_city_age alongside each customer row.
SELECT customer_name, city, age,
AVG(age) OVER(PARTITION BY city) AS avg_city_age
FROM customers;


-- B4. Write a CTE that finds active customers only.
-- Then SELECT customer_name, city, signup_date from it.
WITH active_customers AS (
    SELECT customer_name, city, signup_date
    FROM customers
    WHERE is_active = TRUE
)

SELECT customer_name, city, signup_date
FROM active_customers;


-- B5. Show order_id, order_date, total_amount, and a running
-- total of total_amount ordered by order_date.
-- Call it running_revenue.
SELECT order_id , order_date, total_amount,
	SUM(total_amount) OVER (ORDER BY order_date) AS running_revenue
FROM orders;





