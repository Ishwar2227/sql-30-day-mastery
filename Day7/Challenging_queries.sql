-- C1. Build a revenue pivot table showing total revenue
-- per category broken down by order status.
-- Output columns: category, delivered_revenue,
-- cancelled_revenue, other_revenue.
-- Use CASE inside SUM.
SELECT 
    p.category,

    SUM(CASE 
        WHEN o.status = 'delivered' 
        THEN oi.quantity * oi.unit_price 
        ELSE 0 
    END) AS delivered_revenue,

    SUM(CASE 
        WHEN o.status = 'cancelled' 
        THEN oi.quantity * oi.unit_price 
        ELSE 0 
    END) AS cancelled_revenue,

    SUM(CASE 
        WHEN o.status NOT IN ('delivered', 'cancelled') 
        THEN oi.quantity * oi.unit_price 
        ELSE 0 
    END) AS other_revenue

FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id

GROUP BY p.category;


-- C2. Write a query that scores each customer:
-- +3 points if total_spent > 1000
-- +2 points if they have more than 1 order
-- +1 point if they have a non-null email
-- Show customer_name and total_score.
-- Hint: SUM of multiple CASE expressions.
SELECT c.customer_name ,
(
	CASE 
		WHEN SUM(o.total_amount) >1000 THEN 3
		ELSE 0
	END
	+
	CASE
		WHEN COUNT(o.order_id) > 1 THEN 2
		ELSE 0
	END
	+
	CASE 
		WHEN c.email IS NOT NULL THEN 1 
		ELSE 0
	END
) AS total_score
FROM customers c 
LEFT JOIN orders o
ON c.customer_id = o.customer_id 
GROUP BY c.customer_id , c.customer_name, c.email;


-- C3. Classify each city's customer base:
-- If avg age > 35 AND customer count > 1 → 'Prime Market'
-- If avg age > 35 OR customer count > 1 → 'Potential Market'
-- Otherwise → 'Developing Market'
-- Show city, avg_age, customer_count, market_type.
SELECT city, AVG(age) AS avg_age , COUNT(customer_id) AS customer_count, 
CASE 
		WHEN AVG(age) >35 AND COUNT(customer_id) > 1 THEN 'Prime Market'
		WHEN AVG(age) > 35 OR COUNT(customer_id) > 1 THEN 'Potential Market'
		ELSE 'Developing Market'
END AS market_type 
FROM customers
GROUP BY city;
