-- C1. Find the city with the highest total customer spend.
-- You'll need to JOIN customers and orders first,
-- then aggregate. Output: city, total_spend.
-- (Preview of JOINs — figure out the logic,
-- we cover JOINs properly on Day 5-6)
SELECT 
    c.city,
    SUM(o.total_amount) AS total_spend
FROM customers c
JOIN orders o 
ON c.customer_id = o.customer_id
GROUP BY c.city
ORDER BY total_spend DESC
LIMIT 1;



-- C2. Find the percentage of orders that were delivered.
-- Output a single number like 40.00 (as a percentage).
-- Think: delivered orders / total orders * 100.
-- You'll need COUNT with a condition inside it.
-- Hint: COUNT(NULLIF(condition, false)) or a CASE inside COUNT.
SELECT 
    (COUNT(*) FILTER (WHERE status = 'delivered') * 100.0 
    / COUNT(*)) AS delivered_percentage
FROM orders;


-- C3. Write a query that shows each city and labels it:
-- - 'High' if average customer age > 35
-- - 'Low' if average customer age <= 35
-- You'll need CASE (your first use of it — figure out the syntax,
-- it's intuitive). Output: city, avg_age, age_group.
SELECT
    city,
    AVG(age) AS avg_age,
    CASE
        WHEN AVG(age) > 35 THEN 'High'
        ELSE 'Low'
    END AS age_group
FROM customers
GROUP BY city;
