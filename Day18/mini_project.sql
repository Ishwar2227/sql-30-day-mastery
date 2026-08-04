-- ## Mini Project — "Production Query Audit"
-- Your senior engineer says:

--  *"Before we go to production, I need a full performance audit of our most critical queries. Run EXPLAIN ANALYZE on each, add the right indexes, document the before/after, and build a reusable query runner in Python."*

-- **Part 1 — Query Audit:**
-- Run EXPLAIN ANALYZE on these three queries. Document before/after with indexes:
-- - Query 1: Customer spend report (JOIN + GROUP BY)
-- - Query 2: Active customer filter (WHERE is_active + city)
-- - Query 3: Order status distribution (GROUP BY status)


--Query 1
EXPLAIN ANALYZE
SELECT c.customer_name, SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;
--Before
--HashAggregate (cost=2.55..2.67 rows=10 width=47) (actual time=1.347..1.357 rows=8.00 loops=1)
--Execution Time: 2.275 ms

CREATE INDEX customer_indx 
ON orders (customer_id, total_amount);
--After 
--HashAggregate  (cost=2.55..2.67 rows=10 width=47) (actual time=0.087..0.091 rows=8.00 loops=1)
--Execution Time: 0.164 ms

--Query 2
EXPLAIN ANALYZE
SELECT customer_id,
       customer_name,
       city
FROM customers
WHERE is_active = TRUE
  AND city = 'Pune';
--Before 
--Seq Scan on customers  (cost=0.00..1.20 rows=4 width=21) (actual time=0.019..0.023 rows=4.00 loops=1)
--Execution Time: 0.041 ms
CREATE INDEX idx_customers_active_city
ON customers(is_active, city);
--After 
--Seq Scan on customers  (cost=0.00..1.20 rows=4 width=21) (actual time=0.025..0.032 rows=4.00 loops=1)
--Execution Time: 0.056 ms

--Query 3
EXPLAIN ANALYZE
SELECT status,
       COUNT(*) AS total_orders
FROM orders
GROUP BY status;
--Before 
--HashAggregate  (cost=1.15..1.19 rows=4 width=17) (actual time=0.077..0.079 rows=4.00 loops=1)
-- Seq Scan on orders  (cost=0.00..1.10 rows=10 width=9) (actual time=0.048..0.049 rows=10.00 loops=1)
--Execution Time: 0.186 ms

CREATE INDEX idx_orders_status 
ON orders(status);
--After
--HashAggregate  (cost=1.15..1.19 rows=4 width=17) (actual time=0.036..0.038 rows=4.00 loops=1)
-- Seq Scan on orders  (cost=0.00..1.10 rows=10 width=9) (actual time=0.015..0.016 rows=10.00 loops=1)
--Execution Time: 0.073 ms


-- # **Part 2 — Index Strategy:**
-- # Write CREATE INDEX statements for each query above with explanation comments saying which query benefits and why.

-- Query 1: Customer Spend Report
-- Benefits:
-- customer_id is used in the JOIN condition.
-- total_amount is used for calculating SUM(total_amount).
-- This index helps PostgreSQL locate matching orders
-- and may allow Index Only Scan on large datasets.
CREATE INDEX idx_orders_customer_total
ON orders(customer_id, total_amount);

-- Query 2: Active Customer Filter
-- Benefits:
-- The query filters using WHERE is_active AND city.
-- Composite index allows PostgreSQL to quickly locate
-- matching active customers in a particular city
-- instead of scanning the entire customers table.
CREATE INDEX idx_customers_active_city
ON customers(is_active, city);

-- Query 3: Order Status Distribution
-- Benefits:
-- status is used in GROUP BY.
-- On large tables this index can reduce the amount of
-- data PostgreSQL needs to process while grouping
-- orders by status.
CREATE INDEX idx_orders_status
ON orders(status);
