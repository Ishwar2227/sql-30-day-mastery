-- C1. Find customers who placed orders in consecutive months.
-- Show customer_name, order_date, prev_order_date.
-- Use LAG to get the previous order date per customer.
-- Hint: PARTITION BY customer_id ORDER BY order_date.
SELECT c.customer_name , o.order_date,
LAG(o.order_date) OVER(PARTITION BY c.customer_id ORDER BY o.order_date) AS prev_order_date,
ROW_NUMBER() OVER(ORDER BY o.order_date) AS list_customers
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id;


-- C2. Build a running revenue report by month.
-- Show month, monthly_revenue, cumulative_revenue.
-- Use DATE_TRUNC('month', order_date) to group by month.
-- Use SUM OVER (ORDER BY month) for cumulative.
WITH monthly_revenue AS (
SELECT 
		DATE_TRUNC('month',order_date) AS month,
		SUM(total_amount) AS monthly_revenue,
FROM orders
GROUP BY month
)
SELECT month , monthly_revenue,
SUM(monthly_revenue) OVER(ORDER BY month) AS cumulative_revenue
FROM monthly_revenue;


-- C3. Rank products by revenue within each category.
-- Show category, product_name, product_revenue, rank_in_category.
-- Use DENSE_RANK OVER (PARTITION BY category ORDER BY revenue DESC).
-- Only show rank 1 products per category (top product per category).
WITH products_revenue AS (

    SELECT 
        p.category,
        p.product_name,

        SUM(oi.quantity * oi.unit_price) AS product_revenue,

        DENSE_RANK() OVER (
            PARTITION BY p.category
            ORDER BY SUM(oi.quantity * oi.unit_price) DESC
        ) AS rank_in_category

    FROM products p

    JOIN order_items oi
    ON p.product_id = oi.product_id

    GROUP BY p.category, p.product_name
)

SELECT 
    category,
    product_name,
    product_revenue,
    rank_in_category

FROM products_revenue

WHERE rank_in_category = 1;
