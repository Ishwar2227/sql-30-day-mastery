-- I1. Create a customer segmentation report.
-- Join customers and orders, calculate total_spent per customer.
-- Categorize:
-- total_spent >= 1000 → 'High Value'
-- total_spent >= 500  → 'Mid Value'
-- total_spent < 500   → 'Low Value'
-- Show customer_name, total_spent, segment.
SELECT c.customer_name , SUM(o.total_amount) AS total_spent,
CASE 
	WHEN SUM(o.total_amount) >= 1000 THEN 'High Value'
	WHEN SUM(o.total_amount) >= 500 THEN 'Mid value'
	WHEN SUM(o.total_amount) < 500 THEN 'Low value'
	ELSE 'Unknown value'
END AS segment 
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id 
GROUP BY c.customer_id, c.customer_name;


-- I2. Write a single query that shows a status summary:
-- One row, four columns:
-- total_orders, delivered_count, cancelled_count, processing_count
-- Use CASE inside COUNT.
SELECT 
		COUNT(*) AS total_orders,
		COUNT(CASE WHEN status = 'delivered' THEN 1 END) AS delivered_count,
		COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS cancelled_count,
		COUNT(CASE WHEN status = 'processing' THEN 1 END) AS processing_count
FROM orders;


-- I3. Show each order with customer_name, total_amount, and a
-- 'priority_flag' column:
-- Above average total_amount AND status = 'delivered' → 'High Priority'
-- Above average total_amount only → 'Watch'
-- Everything else → 'Normal'
-- Use a subquery for the average inside CASE.
SELECT 
    c.customer_name,
    o.total_amount,
    CASE 
        WHEN o.total_amount > (SELECT AVG(total_amount) FROM orders)
             AND o.status = 'delivered' THEN 'High Priority'
        WHEN o.total_amount > (SELECT AVG(total_amount) FROM orders) THEN 'Watch'
        ELSE 'Normal'
    END AS priority_flag
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;

-- I4. Add a 'discount_eligible' column to orders:
-- total_amount > 500 AND status = 'delivered' → 'Yes'
-- Otherwise → 'No'
-- Show order_id, total_amount, status, discount_eligible.
SELECT order_id , total_amount , status ,
CASE 
		WHEN total_amount > 500 AND status = 'delivered' THEN 'Yes'
		ELSE 'No'
END AS discount_eligible
FROM orders;


-- I5. Show customer_name, city, and a 'signup_era' column:
-- signed up before 2024 → 'Early Adopter'
-- signed up in 2024 → 'Recent'
-- Show all customers.
SELECT customer_name, city,
CASE 
    WHEN signup_date < '2024-01-01' THEN 'Early Adopter'
    WHEN signup_date >= '2024-01-01' THEN 'Recent'
END AS signup_era
FROM customers;