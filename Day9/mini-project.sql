-- Your manager says:
-- "We're having performance issues with our reporting queries. Audit our three most common queries, run EXPLAIN ANALYZE on each, identify what's slow, add appropriate indexes, and document what changed."*


-- The three queries to audit:
-- -- Query 1: Find all active customers from Mumbai or Pune
-- SELECT customer_name, city, email FROM customers
-- WHERE is_active = TRUE AND city IN ('Mumbai', 'Pune');

-- -- Query 2: Find delivered orders above 500
-- SELECT order_id, customer_id, total_amount FROM orders
-- WHERE status = 'delivered' AND total_amount > 500;

-- -- Query 3: Customer total spend report
-- SELECT c.customer_name, SUM(o.total_amount) AS total_spent
-- FROM customers c
-- JOIN orders o ON c.customer_id = o.customer_id
-- GROUP BY c.customer_id, c.customer_name
-- ORDER BY total_spent DESC;


-- Requirements:
-- - Run `EXPLAIN ANALYZE` on each query before adding indexes
-- - Add appropriate indexes for each
-- - Run `EXPLAIN ANALYZE` again after
-- - Document in SQL comments: what scan type changed, what the execution time difference was
-- - Explain in comments why you chose each index
-- - 3-line header comment explaining the audit purpose

-- Performance Audit Report
-- Analyze common reporting queries before and after indexing
-- Compare scan types, execution times, and document optimization impact

/*************************************************
QUERY 1
Active customers from Mumbai or Pune
*************************************************/

-- BEFORE INDEX
EXPLAIN ANALYZE
SELECT customer_name, city, email
FROM customers
WHERE is_active = TRUE
  AND city IN ('Mumbai', 'Pune');

-- Findings:
-- Scan Type: Seq Scan (fill from EXPLAIN output)
-- Execution Time: _____ ms
-- Reason: No index available on city filter

-- Index Choice:
-- city is used in the WHERE clause and is frequently filtered
CREATE INDEX idx_customers_city
ON customers(city);

-- AFTER INDEX
EXPLAIN ANALYZE
SELECT customer_name, city, email
FROM customers
WHERE is_active = TRUE
  AND city IN ('Mumbai', 'Pune');

-- Findings:
-- Scan Type: ______
-- Execution Time: _____ ms
-- Change: __________________________
-- Note: Small tables may still use Seq Scan.

/*************************************************
QUERY 2
Delivered orders above 500
*************************************************/

-- BEFORE INDEX
EXPLAIN ANALYZE
SELECT order_id, customer_id, total_amount
FROM orders
WHERE status = 'delivered'
  AND total_amount > 500;

-- Findings:
-- Scan Type: Seq Scan
-- Execution Time: _____ ms

-- Index Choice:
-- status and total_amount are both filtering columns
CREATE INDEX idx_orders_status_amount
ON orders(status, total_amount);

-- AFTER INDEX
EXPLAIN ANALYZE
SELECT order_id, customer_id, total_amount
FROM orders
WHERE status = 'delivered'
  AND total_amount > 500;

-- Findings:
-- Scan Type: ______
-- Execution Time: _____ ms
-- Change: __________________________
-- Composite index helps PostgreSQL filter both conditions efficiently.

/*************************************************
QUERY 3
Customer Spend Report
*************************************************/

-- BEFORE INDEX
EXPLAIN ANALYZE
SELECT c.customer_name,
       SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC;

-- Findings:
-- Join Type: ______
-- Scan Type: ______
-- Execution Time: _____ ms

-- Index Choice:
-- customer_id is the JOIN key
CREATE INDEX idx_orders_customer_id
ON orders(customer_id);

-- AFTER INDEX
EXPLAIN ANALYZE
SELECT c.customer_name,
       SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC;
