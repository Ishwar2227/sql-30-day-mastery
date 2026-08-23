# Mini Project — "Churn Prediction Feature Pipeline"
# Your ML engineer says:
# > *"I need a production-ready feature pipeline for our churn prediction model. Build the feature table, create the churn labels, do the train/test split, and hand me a clean CSV."*
# Build a complete Python script:
# python
# ```python
# # 1. Connect to ecommerce_project database
# # 2. Run the master feature query (all features + churn label)
# # 3. Load into pandas
# # 4. Print data quality report (nulls, dtypes, describe)
# # 5. Handle nulls (fill with median)
# # 6. Scale features
# # 7. Add train/test split column
# # 8. Save to 'churn_features.csv'
# # 9. Print: shape, churn rate, train/test distribution
# ```
# Save as `day24_churn_pipeline.py`. Push to GitHub in `Day24/`.
# 3-line comment at top explaining what the pipeline does.

"""
Builds a churn-prediction feature pipeline from PostgreSQL customer data.
Creates customer features and churn labels, cleans and scales the data.
Then creates a deterministic train/test split and exports the ML-ready CSV.
"""

import pandas as pd
import psycopg2
from sklearn.preprocessing import StandardScaler

conn = psycopg2.connect(
    host="localhost",
    database="ecommerce_project",
    user="postgres",
    password="YOUR_PASSWORD",
    port="5432"
)

# ============================================================
# 2. MASTER FEATURE QUERY + CHURN LABEL
# ============================================================

query = """
WITH customer_features AS (

    SELECT
        fo.customer_id,

        -- Recency
        (
            SELECT MAX(order_date)
            FROM fact_orders
        ) - MAX(fo.order_date) AS recency_days,

        -- Frequency
        COUNT(DISTINCT fo.order_id) AS frequency,

        -- Monetary
        ROUND(
            SUM(
                fi.unit_price
                * fi.quantity
                * (1 - fi.discount_pct / 100.0)
            ), 2
        ) AS monetary,

        -- Category diversity
        COUNT(DISTINCT dp.category) AS category_diversity,

        -- Cancelled order percentage
        ROUND(
            COUNT(
                DISTINCT CASE
                    WHEN fo.status = 'cancelled'
                    THEN fo.order_id
                END
            ) * 100.0
            / NULLIF(
                COUNT(DISTINCT fo.order_id),
                0
            ),
            2
        ) AS cancelled_pct,

        -- Last order date
        MAX(fo.order_date) AS last_order_date

    FROM fact_orders fo

    JOIN fact_order_items fi
        ON fo.order_id = fi.order_id

    JOIN dim_products dp
        ON fi.product_id = dp.product_id

    GROUP BY fo.customer_id
),

final_features AS (

    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        category_diversity,
        cancelled_pct,

        CASE
            WHEN recency_days > 60
            THEN 1
            ELSE 0
        END AS is_churned

    FROM customer_features
)

SELECT *
FROM final_features
ORDER BY customer_id;
"""

# ============================================================
# 3. LOAD DATA INTO PANDAS
# ============================================================

df = pd.read_sql(query, conn)

conn.close()

print("\nData loaded successfully.")

# ============================================================
# 4. DATA QUALITY REPORT
# ============================================================

print("\n" + "=" * 60)
print("DATA QUALITY REPORT")
print("=" * 60)

print("\n--- NULL COUNT ---")
print(df.isnull().sum())

print("\n--- DATA TYPES ---")
print(df.dtypes)

print("\n--- DESCRIPTIVE STATISTICS ---")
print(df.describe())

# ============================================================
# 5. HANDLE NULL VALUES
# ============================================================

feature_columns = [
    "recency_days",
    "frequency",
    "monetary",
    "category_diversity",
    "cancelled_pct"
]

for column in feature_columns:
    df[column] = df[column].fillna(
        df[column].median()
    )

# ============================================================
# 6. SCALE FEATURES
# ============================================================

scaler = StandardScaler()

df[feature_columns] = scaler.fit_transform(
    df[feature_columns]
)

# ============================================================
# 7. ADD TRAIN / TEST SPLIT
# ============================================================

# Deterministic split based on customer_id.
# Same customer will consistently remain in the same split.

df["hash_value"] = (
    pd.util.hash_pandas_object(
        df["customer_id"],
        index=False
    )
)

df["dataset_split"] = df["hash_value"].apply(
    lambda x: "train"
    if x % 10 < 7
    else "test"
)

df.drop(
    columns=["hash_value"],
    inplace=True
)

# ============================================================
# 8. SAVE ML-READY CSV
# ============================================================

df.to_csv(
    "churn_features.csv",
    index=False
)

print("\nSaved: churn_features.csv")

# ============================================================
# 9. FINAL REPORT
# ============================================================

print("\n" + "=" * 60)
print("FINAL PIPELINE REPORT")
print("=" * 60)

print("\nShape:")
print(df.shape)

print("\nChurn rate:")

churn_rate = df["is_churned"].mean() * 100

print(f"{churn_rate:.2f}%")

print("\nTrain/Test distribution:")

print(
    df["dataset_split"]
    .value_counts()
)

print("\nTrain/Test percentage:")

print(
    df["dataset_split"]
    .value_counts(normalize=True)
    .mul(100)
    .round(2)
)

print("\nFirst 5 rows:")
print(df.head())


