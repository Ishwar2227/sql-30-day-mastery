-- B1. Run EXPLAIN (ANALYZE, BUFFERS) on this query:
-- SELECT c.customer_name, SUM(o.total_amount) AS total_spent
-- FROM customers c
-- JOIN orders o ON c.customer_id = o.customer_id
-- GROUP BY c.customer_id, c.customer_name;

-- Identify in a SQL comment:

-- - What join type did PostgreSQL choose?
-- - What aggregate method was used?
-- - What was the execution time?

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT c.customer_name, SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;
--Hash Join 
--HashAggregate
--Execution Time: 1.434 ms


-- B2. Create a partial index on orders for delivered orders only:
-- CREATE INDEX idx_delivered ON orders(total_amount)
-- WHERE status = 'delivered';

-- Then run EXPLAIN ANALYZE on:
-- SELECT order_id, total_amount FROM orders
-- WHERE status = 'delivered' AND total_amount > 500;

-- Did PostgreSQL use the partial index? Note in comment.


CREATE INDEX idx_delivered ON orders(total_amount)
WHERE status = 'delivered';

EXPLAIN (ANALYZE, FORMAT TEXT)
SELECT order_id, total_amount FROM orders
WHERE status = 'delivered' AND total_amount > 500;
--No it used seq scan , because the rows were less 
--Execution Time: 0.125 ms


-- B3. Create a covering index:
-- CREATE INDEX idx_orders_covering
-- ON orders(customer_id)
-- INCLUDE (total_amount, order_date, status);

-- Run EXPLAIN ANALYZE on:
-- SELECT total_amount, order_date, status
-- FROM orders WHERE customer_id = 1;

-- Did you get an Index Only Scan? Note in comment.


CREATE INDEX idx_orders_covering
ON orders(customer_id)
INCLUDE (total_amount, order_date, status);

EXPLAIN ANALYZE
SELECT total_amount, order_date, status
FROM orders WHERE customer_id = 1;
--No it used seq scan 


-- B4. Run VACUUM ANALYZE on both customers and orders tables.
-- Then run EXPLAIN ANALYZE on any query from Day 12.
-- Did the cost estimate change? Note it in a comment.

-- VACUUM ANALYZE customers;
-- VACUUM ANALYZE orders;

EXPLAIN ANALYZE 
SELECT order_date,
       SUM(total_amount) AS daily_revenue,
FROM orders
GROUP BY order_date
ORDER BY order_date;
--GroupAggregate  (cost=1.27..1.47 rows=10 width=36) (actual time=0.048..0.053 rows=10.00 loops=1)
--  Group Key: order_date
--Execution Time: 0.085 ms


-- B5. Write a Python script using SQLAlchemy with connection
-- pooling configured (pool_size=5, max_overflow=10).
-- Run 3 queries using the same engine object.
-- Print "Connection pool active" after each query.


from sqlalchemy import create_engine
import pandas as pd

engine = create_engine(
	'postgresql://postgres:ishwar@localhost:5432/sql_practice',
	pool_size = 5,
	max_overflow=10
) 

query1 = """
    SELECT order_date,
       SUM(total_amount) AS daily_revenue
FROM orders
GROUP BY order_date
ORDER BY order_date;
"""

query2 = """
    WITH first_order AS (
		SELECT customer_name,
			MIN(order_date) AS first_order_date
		FROM orders o
		JOIN customers c ON c.customer_id = o.customer_id
		GROUP BY customer_name
)
SELECT customer_name,first_order_date
FROM first_order;
"""

query3 = """
   SELECT customer_name,
		COUNT(DISTINCT order_id) AS order_count,
		CASE WHEN COUNT(DISTINCT order_id) > 1
			THEN 'Repeat' ELSE 'One-time'
		END AS customer_type
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY customer_name;
"""
df1 = pd.read_sql(query1,engine)
print(df1.head())
print("Connection pool active")

df2 = pd.read_sql(query2,engine)
print(df2.head())
print("Connection pool active")

df3 = pd.read_sql(query3,engine)
print(df3.head())
print("Connection pool active")

print(engine.pool.status())

#Pool size: 5  Connections in pool: 1 Current Overflow: -4 Current Checked out connections: 0


-- ## 🟡 Intermediate

-- I1. Create a partitioned version of the orders table.
-- Partition by year: 2023 and 2024.
-- Insert 2 rows into each partition manually.
-- Run EXPLAIN ANALYZE on:
-- SELECT * FROM orders_partitioned WHERE order_date >= '2024-01-01';
-- Does the plan show partition pruning? Note in comment.


CREATE TABLE orders_partitioned(
		order_id SERIAL,
		customer_id INT,
		order_date DATE,
		total_amount NUMERIC(10,2),
		status VARCHAR(20)
) PARTITION BY RANGE(order_date);

CREATE TABLE orders_2023
	PARTITION OF orders_partitioned
	FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
	
CREATE TABLE orders_2024
	PARTITION OF orders_partitioned
	FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
	
INSERT INTO orders_partitioned(order_id ,customer_id,order_date,total_amount,status)
VALUES
(1,01,'2024-12-22',20000,'avtive'),
(2,03,'2023-06-27',22000,'avtive');
	
EXPLAIN ANAYZE 
SELECT * FROM orders_partitioned WHERE order_date >= '2024-01-01';
--Seq Scan on orders_2024 orders_partitioned  (cost=0.00..18.88 rows=237 width=86) (actual time=0.037..0.038 rows=2.00 loops=1)


-- I2. Find the top 3 slowest-running query patterns
-- from your pg_stat_statements view (if enabled).
-- If not enabled, write the query that would check it:
-- SELECT query, mean_exec_time, calls
-- FROM pg_stat_statements
-- ORDER BY mean_exec_time DESC LIMIT 3;
-- Note: this may require superuser access.

SELECT
    query,
    mean_exec_time,
    calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 3;
--SELECT set_config($1,$2,$3) FROM pg_show_all_settings() WHERE name = $4
--SELECT set_config($1,$2,$3) FROM pg_show_all_settings() WHERE name = $4
--SELECT set_config($1,$2,$3) FROM pg_show_all_settings() WHERE name = $4


-- I3. Write a query that identifies tables with high
-- dead tuple counts (candidates for VACUUM):
-- SELECT relname, n_dead_tup, n_live_tup,
-- ROUND(n_dead_tup * 100.0 /
-- NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_pct
-- FROM pg_stat_user_tables
-- ORDER BY n_dead_tup DESC;
-- Run it. Which table has the most dead tuples?

SELECT relname, n_dead_tup, n_live_tup,
ROUND(n_dead_tup * 100.0 /
NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_pct
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;


-- I4. Compare these two queries using EXPLAIN ANALYZE.
-- Identify which is faster and exactly why:

Query A:
SELECT customer_name FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders
WHERE status = 'delivered');

Query B:
SELECT DISTINCT c.customer_name FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'delivered';


EXPLAIN ANALYZE
SELECT customer_name FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders
WHERE status = 'delivered');
--Hash semi join 
--Execution Time: 0.809 ms

EXPLAIN ANALYZE
SELECT DISTINCT c.customer_name FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'delivered';
--HashAggregate 
--Execution Time: 0.151 ms
-- second query is faster compare to first one , 
--bcoz the first query needs to find in the table which takes quite more time compare to second one 


-- I5. Write the query to check index usage statistics:
-- SELECT indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
-- FROM pg_stat_user_indexes
-- WHERE schemaname = 'public'
-- ORDER BY idx_scan DESC;
-- Which index has been used the most?

SELECT indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
--index scan and index tupl read are same 
-- whereas ind_tup_feth is less compared to both



