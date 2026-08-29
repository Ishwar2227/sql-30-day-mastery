-- C1. Build a 3-month rolling feature window for each customer.
-- For each customer-month, compute:
-- - monthly_revenue (that month)
-- - rolling_3m_revenue (3-month rolling sum)
-- - rolling_3m_orders (3-month rolling count)
-- - rolling_3m_avg_order (rolling average)
-- - is_growing (1 if this month > prev month, else 0)
-- This is a feature set for a next-month prediction model.

WITH customer_info AS(
	SELECT 
		customer_id,
		DATE_TRUNC('month',order_date) AS month,
		ROUND(SUM(unit_price * quantity *(1 - discount_pct / 100.0)), 2
        ) AS monthly_revenue,
		COUNT(DISTINCT fo.order_id) AS monthly_orders
	FROM fact_orders fo 
	JOIN fact_order_items fi ON fo.order_id = fi.order_id
	GROUP BY customer_id, DATE_TRUNC('month',order_date)
),
rolling_features AS (
    SELECT
        customer_id,
        month,
        monthly_revenue,
        SUM(monthly_revenue) OVER (
            PARTITION BY customer_id
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_3m_revenue,

        SUM(monthly_orders) OVER (
            PARTITION BY customer_id
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_3m_orders,

        LAG(monthly_revenue) OVER (
            PARTITION BY customer_id
            ORDER BY month
        ) AS previous_month_revenue

    FROM customer_info
)
SELECT 
	customer_id, month, monthly_revenue,
	rolling_3m_revenue,
	rolling_3m_orders,
	ROUND(
		rolling_3m_revenue / NULLIF(rolling_3m_orders,0),2
	) AS rolling_3m_avg_orders,

	CASE WHEN monthly_revenue > previous_month_revenue
	THEN 1 ELSE 0 END AS is_growing
FROM rolling_features
ORDER BY customer_id , month;

-- C2. Create a customer similarity feature:
-- For each customer, compute the Euclidean distance
-- between their spending profile and the average customer:
-- SQRT(
-- (total_spent - avg_total_spent)^2 +
-- (order_count - avg_order_count)^2 +
-- (category_count - avg_category_count)^2
-- ) AS distance_from_average
-- Show customer_id, distance_from_average.
-- Customers far from average are anomalies.

WITH customer_features AS(
	SELECT customer_id,
		ROUND(SUM(unit_price * quantity *(1 - discount_pct / 100.0)),2) AS total_spent,
		COUNT(DISTINCT fi.order_id) AS order_count,
		COUNT(DISTINCT category) AS category_count
	FROM fact_orders fo 
	JOIN fact_order_items fi ON fo.order_id = fi.order_id
	JOIN dim_products dp ON fi.product_id = dp.product_id
	GROUP BY customer_id
),
customer_with_averages AS(
	SELECT 
		customer_id,
		total_spent,
		order_count,category_count,
		AVG(total_spent) OVER() AS avg_total_spent,
		AVG(order_count) OVER() AS avg_order_count,
		AVG(category_count) OVER() AS avg_category_count
	FROM customer_features
)
SELECT 
	customer_id,
	SQRT(
		POWER(total_spent - avg_total_spent,2)
		+
		POWER(order_count - avg_order_count,2)
		+
		POWER(category_count - avg_category_count, 2)
	) AS distance_from_averages
FROM customer_with_averages;


-- C3. Build a complete ML-ready feature matrix and export it.
-- Write a Python script that:
-- 1. Runs your I5 master feature table query
-- 2. Loads into pandas
-- 3. Checks for NULLs (print count per column)
-- 4. Fills NULLs with median values
-- 5. Scales numerical features with StandardScaler
-- 6. Saves the processed matrix to 'ml_features.csv'
-- 7. Prints the shape and first 5 rows

import pandas as pd
import psycopg2
from sklearn.preprocessing import StandardScaler

conn = psycopg2.connect(
    host="localhost",
    database="ecommerce_project",
    user="postgres",
    password="ishwar",
    port="5432"
)

query = """
WITH rfm_features AS (
    SELECT
        fo.customer_id,

        (
            SELECT MAX(order_date)
            FROM fact_orders
        ) - MAX(fo.order_date) AS recency_days,

        COUNT(DISTINCT fo.order_id) AS frequency,

        ROUND(
            SUM(
                fi.unit_price
                * fi.quantity
                * (1 - fi.discount_pct / 100.0)
            ), 2
        ) AS monetary

    FROM fact_orders fo

    JOIN fact_order_items fi
        ON fo.order_id = fi.order_id

    GROUP BY fo.customer_id
),

diversity_features AS (
    SELECT
        fo.customer_id,

        COUNT(DISTINCT dp.category) AS category_diversity,

        ROUND(
            COUNT(DISTINCT CASE
                WHEN fo.status = 'cancelled'
                THEN fo.order_id
            END) * 100.0
            / NULLIF(COUNT(DISTINCT fo.order_id), 0),
            2
        ) AS cancelled_pct

    FROM fact_orders fo

    JOIN fact_order_items fi
        ON fo.order_id = fi.order_id

    JOIN dim_products dp
        ON fi.product_id = dp.product_id

    GROUP BY fo.customer_id
),

churn_labels AS (
    SELECT
        customer_id,

        CASE
            WHEN
                (
                    SELECT MAX(order_date)
                    FROM fact_orders
                ) - MAX(order_date) > 60
            THEN 1
            ELSE 0
        END AS is_churned

    FROM fact_orders

    GROUP BY customer_id
)

SELECT
    r.customer_id,
    r.recency_days,
    r.frequency,
    r.monetary,
    d.category_diversity,
    d.cancelled_pct,
    c.is_churned

FROM rfm_features r

JOIN diversity_features d
    ON r.customer_id = d.customer_id

JOIN churn_labels c
    ON r.customer_id = c.customer_id

ORDER BY r.customer_id;
"""
df = pd.read_sql(query, conn)
conn.close()

print("\nNULL COUNT PER COLUMN:")
print(df.isnull().sum())

feature_columns = [
    "recency_days",
    "frequency",
    "monetary",
    "category_diversity",
    "cancelled_pct",
    "is_churned"
]

df[feature_columns] = df[feature_columns].apply(
    lambda column: column.fillna(column.median())
)

scaler = StandardScaler()

df[feature_columns] = scaler.fit_transform(
    df[feature_columns]
)

df.to_csv(
    "ml_features.csv",
    index=False
)

print("\nFeature matrix shape:")
print(df.shape)

print("\nFirst 5 rows:")
print(df.head())