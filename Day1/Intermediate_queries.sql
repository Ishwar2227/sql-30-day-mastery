-- Orders in January 2024
SELECT *
FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-01-31';


SELECT *
FROM orders
WHERE order_date >= '2024-01-01'
AND order_date < '2024-02-01';

--  I2 — Customers from Mumbai or Delhi AND age > 25

SELECT *
FROM customers
WHERE city IN ('Mumbai', 'Delhi')
AND age > 25;

--  I3 — Orders not cancelled + amount range
SELECT *
FROM orders
WHERE status <> 'cancelled'
AND total_amount BETWEEN 200 AND 1000;



--I4 — Top 5 highest-value orders
SELECT order_id, customer_id, amount
FROM orders
ORDER BY amount DESC
LIMIT 5;


--I5 — Name starts with 'A' OR ends with 'a'
SELECT *
FROM customers
WHERE customer_name ILIKE 'A%'
OR customer_name ILIKE '%a';
