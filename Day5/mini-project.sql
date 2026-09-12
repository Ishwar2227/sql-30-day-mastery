-- Your manager asks:
-- "Show me a complete breakdown of what each customer bought, from which category, at what price, and in which order. Only include delivered orders. Sort by customer name then by product category."*

-- Requirements:
-- - Columns: `customer_name`, `city`, `product_name`, `category`, `unit_price`, `order_date`
-- - Filter: delivered orders only
-- - All 4 tables joined
-- - 3-line comment
-- - ORDER BY customer_name ASC, category ASC

-- -- customer activity report with all details about orders 
-- -- Only includes the customers who's oreder is delivered 
-- -- includes customer name and product and city of customer 
SELECT c.customer_name , c.city, p.product_name , p.category, oi.unit_price , o.order_date
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id 
WHERE o.status = 'delivered'
ORDER BY c.customer_name , p.category ASC;