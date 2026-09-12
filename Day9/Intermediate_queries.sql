-- I1. Write a query using EXISTS to check if a customer
-- has placed any order. Compare it with the COUNT approach.
-- Run EXPLAIN on both and compare the plans.
-- Which is more efficient and why?

EXPLAIN ANALYZE SELECT customer_name FROM customers c
WHERE EXISTS(SELECT 1 FROM orders WHERE customer_id = c.customer_id);
--Seq scan 
--planning time - 0.379 ,execution time - 0.475

EXPLAIN ANALYZE SELECT customer_name FROM customers c
WHERE (SELECT COUNT(*) FROM orders WHERE customer_id = c.customer_id) > 0;
--seq scan , planning time : 0.314 , Execution time : 0.228

-- On 10 rows, timing fluctuates by microseconds and means nothing. At 1 million rows, 
--EXISTS stops scanning the moment it finds the first match. COUNT(*) scans and 
--counts every single matching row even after it already knows "yes, at least one exists." 
--EXISTS is fundamentally more efficient at scale. Never judge query efficiency on small test data.


-- I2. You have this query — rewrite it to be more efficient:
-- SELECT * FROM customers
-- WHERE UPPER(customer_name) = 'AISHA SHARMA'
-- Write the optimized version and explain why it's faster.

-- Option 1: Use ILIKE for case-insensitive match (index-friendly with right setup)
SELECT customer_name FROM customers
WHERE customer_name ILIKE 'Aisha Sharma';

-- Option 2: Store names consistently (all same case) at insert time
-- Then simple equality works: WHERE customer_name = 'Aisha Sharma'


-- I3. Create a composite index on orders(customer_id, status).
-- Write a query that benefits from this index.
-- Run EXPLAIN ANALYZE and note whether the index is used.

CREATE INDEX cust_indx ON orders(customer_id,status);

EXPLAIN ANALYZE
SELECT order_id , order_date, total_amount FROM orders  
WHERE customer_id = 2 AND status = 'delivered';


-- I4. Write a query that retrieves customer_name and total_spent
-- using a CTE. Then run EXPLAIN ANALYZE on it.
-- Identify the most expensive node in the plan.
EXPLAIN ANALYZE WITH customer_details AS (
		SELECT c.customer_name , SUM(o.total_amount) AS total_spent 
		FROM customers c 
		JOIN orders o ON c.customer_id = o.customer_id
		GROUP BY c.customer_name
)
SELECT customer_name , total_spent 
FROM customer_details;
--Planning time : 0.538 , The HashAggregate node (for GROUP BY) is typically the most expensive in this query 


-- I5. This query is slow — identify all the problems and fix them:
-- SELECT * FROM customers c, orders o
-- WHERE c.customer_id = o.customer_id
-- AND EXTRACT(YEAR FROM o.order_date) = 2024
-- AND o.status = 'delivered'
SELECT c.customer_name , o.order_date, o.status 
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id 
WHERE o.order_date >= '2024-01-01' AND o.order_date < '2025-01-01'
AND o.status = 'delivered';
