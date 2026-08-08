from sqlalchemy import create_engine 
import pandas as pd

engine = create_engine("postgresql://postgres:ishwar@localhost:5432/ecommerce_project")

section1 = """
    SELECT
    ROUND(
        SUM(foi.unit_price * foi.quantity * (1 - foi.discount_pct/100.0)),
        2
    ) AS total_revenue,

    COUNT(DISTINCT fo.order_id) AS total_orders,

    COUNT(DISTINCT fo.customer_id) AS total_customers,

    ROUND(
        SUM(foi.unit_price * foi.quantity * (1 - foi.discount_pct/100.0))
        / COUNT(DISTINCT fo.order_id),
        2
    ) AS avg_order_value

FROM fact_orders fo
JOIN fact_order_items foi
ON fo.order_id = foi.order_id;
"""

section2 = """
       SELECT
    dp.product_name,

    ROUND(
        SUM(
            foi.unit_price *
            foi.quantity *
            (1 - foi.discount_pct/100.0)
        ),
        2
    ) AS revenue

FROM dim_products dp
JOIN fact_order_items foi
ON dp.product_id = foi.product_id

GROUP BY dp.product_name

ORDER BY revenue DESC

LIMIT 5;
"""

section3 = """
        SELECT
    fo.state,

    ROUND(
        SUM(
            foi.unit_price *
            foi.quantity *
            (1 - foi.discount_pct/100.0)
        ),
        2
    ) AS revenue

FROM fact_orders fo
JOIN fact_order_items foi
ON fo.order_id = foi.order_id

GROUP BY fo.state

ORDER BY revenue DESC;
"""

section4 = """
    WITH monthly_sales AS
(
SELECT
    DATE_TRUNC('month',fo.order_date) AS month,

    SUM(
        foi.unit_price *
        foi.quantity *
        (1 - foi.discount_pct/100.0)
    ) AS revenue

FROM fact_orders fo
JOIN fact_order_items foi
ON fo.order_id = foi.order_id

GROUP BY DATE_TRUNC('month',fo.order_date)
)

SELECT
    month,
    revenue,

    LAG(revenue)
    OVER(ORDER BY month) AS previous_month,

    ROUND(
        (
            revenue -
            LAG(revenue) OVER(ORDER BY month)
        )
        *100.0/
        NULLIF(LAG(revenue) OVER(ORDER BY month),0),
        2
    ) AS mom_growth

FROM monthly_sales

ORDER BY month;
"""

section5 = """
    WITH customer_rfm AS (
    SELECT
        dc.customer_id,
        dc.customer_name,

        (SELECT MAX(order_date) FROM fact_orders)
        - MAX(fo.order_date) AS R,

        COUNT(DISTINCT fo.order_id) AS F,

        SUM(
            foi.unit_price *
            foi.quantity *
            (1 - foi.discount_pct / 100.0)
        ) AS M

    FROM dim_customers dc
    JOIN fact_orders fo
        ON dc.customer_id = fo.customer_id
    JOIN fact_order_items foi
        ON fo.order_id = foi.order_id

    GROUP BY
        dc.customer_id,
        dc.customer_name
),

scores AS (
    SELECT *,
        5 - NTILE(4) OVER (ORDER BY R) AS R_score,
        NTILE(4) OVER (ORDER BY F) AS F_score,
        NTILE(4) OVER (ORDER BY M) AS M_score
    FROM customer_rfm
)

SELECT
    customer_name,
    R,
    F,
    M,
    R_score + F_score + M_score AS rfm_score,

    CASE
        WHEN R_score + F_score + M_score BETWEEN 10 AND 12
            THEN 'Champions'
        WHEN R_score + F_score + M_score BETWEEN 7 AND 9
            THEN 'Loyal Customers'
        WHEN R_score + F_score + M_score BETWEEN 4 AND 6
            THEN 'At Risk'
        ELSE 'Lost'
    END AS segment

FROM scores
ORDER BY rfm_score DESC;
"""

section1_df = pd.read_sql(section1,engine)
section2_df = pd.read_sql(section2,engine)
section3_df = pd.read_sql(section3,engine)
section4_df = pd.read_sql(section4,engine)
section5_df = pd.read_sql(section5,engine)

print("=====EXECUTIVE KPI's=====")
print(section1_df)

print("\n=====TOP 5 PRODUCTS BY REVENUE=====")
print(section2_df)

print("\n=====REVENUE BY STATE=====")
print(section3_df)

print("\n=====MONTHLY REVENUE AND MOM GROWTH=====")
print(section4_df)

print("\n=====CUSTOMER RFM SEGMENTATION=====")
print(section5_df)