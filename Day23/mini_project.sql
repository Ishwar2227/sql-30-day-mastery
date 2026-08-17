-- Your backend engineer says:

--*"The frontend needs a complete customer dashboard API. For each active customer return a structured JSON response with all their data. I need it ready to be returned directly from the database without any Python transformation."*
-- Build one query that returns for each active customer:
-- {
--   "customer_id": 1,
--   "name": "Aisha Sharma",
--   "city": "Mumbai",
--   "state": "Maharashtra",
--   "member_since": "2022-03-15",
--   "stats": {
--     "total_orders": 3,
--     "total_spent": 150000,
--     "avg_order_value": 50000,
--     "days_since_last_order": 15
--   },
--   "top_category": "Electronics",
--   "recent_products": ["MacBook Pro", "Sony Headphones"]
-- }
-- ```
-- Requirements:
-- - One row per active customer
-- - Fully structured JSON using JSON_BUILD_OBJECT and JSON_AGG
-- - `top_category` = category with highest spend for that customer
-- - `recent_products` = last 3 products ordered
-- - `days_since_last_order` = relative to max order date in dataset
-- - 3-line comment explaining what the API endpoint does

-- 1. Build customer-level statistics, top spending category, and the three most recent products.
-- 2. Combine the calculated data into nested JSON objects and JSON arrays for each active customer.
-- 3. Return one complete API-ready customer dashboard JSON document directly from PostgreSQL.

WITH active_customers AS (
    SELECT
        customer_id,
        customer_name,
        city,
        state,
        signup_date
    FROM dim_customers
    WHERE is_active = TRUE
),

customer_stats AS (
    SELECT
        ac.customer_id,
        ac.customer_name,
        ac.city,
        ac.state,
        ac.signup_date,

        COUNT(DISTINCT o.order_id) AS total_orders,

        SUM(
            oi.unit_price
            * oi.quantity
            * (1 - oi.discount_pct / 100.0)
        ) AS total_spent,

        SUM(
            oi.unit_price
            * oi.quantity
            * (1 - oi.discount_pct / 100.0)
        ) / NULLIF(COUNT(DISTINCT o.order_id), 0)
            AS avg_order_value,

        (
            SELECT MAX(order_date)
            FROM fact_orders
        ) - MAX(o.order_date)
            AS days_since_last_order

    FROM active_customers ac

    JOIN fact_orders o
        ON ac.customer_id = o.customer_id

    JOIN fact_order_items oi
        ON o.order_id = oi.order_id

    GROUP BY
        ac.customer_id,
        ac.customer_name,
        ac.city,
        ac.state,
        ac.signup_date
),

top_categories AS (
    SELECT
        cs.customer_id,

        (
            SELECT p2.category

            FROM fact_orders o2

            JOIN fact_order_items oi2
                ON o2.order_id = oi2.order_id

            JOIN dim_products p2
                ON oi2.product_id = p2.product_id

            WHERE o2.customer_id = cs.customer_id

            GROUP BY p2.category

            ORDER BY
                SUM(
                    oi2.unit_price
                    * oi2.quantity
                    * (1 - oi2.discount_pct / 100.0)
                ) DESC

            LIMIT 1
        ) AS top_category

    FROM customer_stats cs
),

recent_products AS (
    SELECT
        cs.customer_id,

        (
            SELECT JSON_AGG(x.product_name)

            FROM (
                SELECT
                    p3.product_name

                FROM fact_orders o3

                JOIN fact_order_items oi3
                    ON o3.order_id = oi3.order_id

                JOIN dim_products p3
                    ON oi3.product_id = p3.product_id

                WHERE o3.customer_id = cs.customer_id

                ORDER BY
                    o3.order_date DESC,
                    o3.order_id DESC

                LIMIT 3
            ) x

        ) AS recent_products

    FROM customer_stats cs
)

SELECT
    JSON_BUILD_OBJECT(
        'customer_id', cs.customer_id
        'name', cs.customer_name,
        'city', cs.city,
        'state', cs.state,
        'member_since', cs.signup_date,
        'stats',
            JSON_BUILD_OBJECT(
                'total_orders', cs.total_orders,
                'total_spent', ROUND(cs.total_spent, 2),
                'avg_order_value', ROUND(cs.avg_order_value, 2),
                'days_since_last_order', cs.days_since_last_order
            ),
        'top_category', tc.top_category,
        'recent_products', rp.recent_products
    ) AS customer_dashboard
FROM customer_stats cs
LEFT JOIN top_categories tc
    ON cs.customer_id = tc.customer_id
LEFT JOIN recent_products rp
    ON cs.customer_id = rp.customer_id
ORDER BY cs.customer_name;
