-- I1. Rank customers by total spend using DENSE_RANK.
-- Show customer_name, total_spent, spend_rank.
-- Use a CTE for the spend calculation first.
WITH customer_totals AS (
		SELECT c.customer_name ,SUM(o.total_amount) AS total_spent 
		FROM customers c 
		JOIN orders o ON c.customer_id = o.customer_id 
		GROUP BY c.customer_name
)
SELECT customer_name , total_spent,
DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spend_rank 
FROM customer_totals;

-- I2. Show each order's total_amount and what percentage
-- it represents of the total revenue across all orders.
-- Show order_id, total_amount, pct_of_total.
-- Use a window function for the total.
SELECT order_id , total_amount,
(total_amount * 100.0 / SUM(total_amount) OVER()) AS pct_of_total
FROM orders;


-- I3. For each order show the previous order's amount using LAG.
-- Show order_id, order_date, total_amount, prev_order_amount.
-- Order by order_date.
SELECT order_id, order_date, total_amount,
LAG(total_amount) OVER (ORDER BY order_date) AS prev_order_amount
FROM orders;


-- I4. Find the top 1 spender per city using ROW_NUMBER
-- inside a CTE. Show city, customer_name, total_spent.
-- Hint: ROW_NUMBER OVER (PARTITION BY city ORDER BY total_spent DESC)
-- then filter WHERE row_num = 1 in outer query.
WITH top_spender AS (
		SELECT c.city, c.customer_name , SUM(o.total_amount) AS total_spent, 
		ROW_NUMBER() OVER (PARTITION BY city  
		ORDER BY SUM(o.total_amount) DESC
		) AS spender_rank
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY city, customer_name 
)
SELECT city, customer_name, total_spent
FROM top_spender
WHERE spender_rank =1 ;


-- I5. Show each customer and how their total_spend compares
-- to the average spend across all customers.
-- Show customer_name, total_spent, avg_spent, difference.
-- Use a window function for the average.
WITH customer_spending AS ( 
		SELECT c.customer_name, SUM(o.total_amount) AS total_spent
		FROM customers c 
		JOIN orders o ON c.customer_id = o.customer_id
		GROUP BY c.customer_name
)
SELECT customer_name, total_spent, 
AVG(total_spent) OVER() AS avg_spent,
(total_spent - AVG(total_spent) OVER()) AS difference 
FROM customer_spending;