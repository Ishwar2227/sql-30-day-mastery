-- B1. Run EXPLAIN on a query that selects all customers from 'Pune'.
-- What scan type does PostgreSQL use? Write it in a comment.
EXPLAIN SELECT customer_name FROM customers WHERE city = 'Pune';
--seq scan 


-- B2. Create an index on the customers table for the city column.
-- Then run EXPLAIN again on the same query.
-- Did the scan type change? Write what happened in a comment.
-- (On small tables PostgreSQL may still use Seq Scan — explain why.)
CREATE INDEX customer_indx on customers(city);
EXPLAIN SELECT customer_name FROM customers WHERE city = 'Pune';
-- no the scan type doesn't changed its still seq scan , because our data is small the data is limited so 


-- B3. Run EXPLAIN ANALYZE on a query that finds all orders
-- with total_amount > 500. Note the execution time in a comment.
EXPLAIN ANALYZE SELECT * FROM orders WHERE total_amount > 500;
--ececuation time - 0.710 ms


-- B4. Create an index on orders(total_amount).
-- Run EXPLAIN ANALYZE again on the same query from B3.
-- Compare execution times in a comment.
CREATE INDEX total_indx ON orders(total_amount);
EXPLAIN ANALYZE SELECT * FROM orders WHERE total_amount > 500;
-- Before index: 0.710 ms
-- After index: 1.224 ms

-- B5. Write the slow version and the fast version of a query
-- that finds customers who signed up in 2024.
-- Slow: using EXTRACT(YEAR FROM signup_date) = 2024
-- Fast: using a date range.
-- Run EXPLAIN on both and note which one would use an index.
EXPLAIN SELECT customer_name FROM customers 
WHERE EXTRACT(YEAR FROM signup_date) = 2024;

EXPLAIN SELECT customer_name FROM customers 
WHERE signup_date >= '2024-01-01' AND signup_date < '2025-01-01';







