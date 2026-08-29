# ============================================================
# DAY 25 - BUSINESS INTELLIGENCE + CHURN ML PIPELINE
# ============================================================
#
# Connects PostgreSQL, loads business views, generates insights,
# builds churn features, trains a logistic regression model,
# and saves churn predictions back to PostgreSQL.
# ============================================================

import pandas as pd
import psycopg2
from sqlalchemy import create_engine

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report


# ============================================================
# 1. CONNECT TO DATABASE
# ============================================================

conn = create_engine('postgresql://postgres:ishwar@localhost:5432/ecommerce_project')
print("Database connected successfully.")


# ============================================================
# 2. LOAD ALL THREE VIEWS
# ============================================================

customer_360 = pd.read_sql(
    "SELECT * FROM v_customer_360",
    conn
)

product_performance = pd.read_sql(
    "SELECT * FROM v_product_performance",
    conn
)

monthly_kpis = pd.read_sql(
    "SELECT * FROM v_monthly_business_kpis",
    conn
)

print("\nViews loaded successfully.")

print("Customer 360:", customer_360.shape)
print("Product Performance:", product_performance.shape)
print("Monthly KPIs:", monthly_kpis.shape)


# ============================================================
# 3A. EXECUTIVE KPI SUMMARY
# ============================================================

print("\n" + "=" * 60)
print("EXECUTIVE KPI SUMMARY")
print("=" * 60)

total_revenue = product_performance["total_revenue"].sum()

total_customers = customer_360["customer_id"].nunique()

total_orders = customer_360["total_orders"].sum()

arpu = total_revenue / total_customers if total_customers else 0

print(f"Total Revenue     : ₹{total_revenue:,.2f}")
print(f"Total Customers   : {total_customers:,}")
print(f"Total Orders      : {total_orders:,}")
print(f"ARPU              : ₹{arpu:,.2f}")


# ============================================================
# 3B. TOP 3 CHURN-RISK HIGH-VALUE CUSTOMERS
# ============================================================

print("\n" + "=" * 60)
print("TOP 3 CHURN-RISK HIGH-VALUE CUSTOMERS")
print("=" * 60)

high_value_churn = customer_360[
    (customer_360["value_segment"] == "High") &
    (customer_360["churn_risk"] == "High")
].copy()

top_3_customers = high_value_churn.sort_values(
    by="total_spent",
    ascending=False
).head(3)

print(
    top_3_customers[
        [
            "customer_id",
            "customer_name",
            "total_spent",
            "days_since_last_order",
            "churn_risk"
        ]
    ].to_string(index=False)
)


# ============================================================
# 3C. MOST PROFITABLE PRODUCT CATEGORY
# ============================================================

print("\n" + "=" * 60)
print("MOST PROFITABLE PRODUCT CATEGORY")
print("=" * 60)

category_profit = (
    product_performance
    .groupby("category")["total_profit"]
    .sum()
    .sort_values(ascending=False)
)

most_profitable_category = category_profit.index[0]

print(
    f"Category : {most_profitable_category}"
)

print(
    f"Profit   : ₹{category_profit.iloc[0]:,.2f}"
)


# ============================================================
# 3D. CUSTOMER HEALTH DISTRIBUTION
# ============================================================

print("\n" + "=" * 60)
print("CUSTOMER HEALTH DISTRIBUTION")
print("=" * 60)

health_distribution = (
    customer_360["churn_risk"]
    .value_counts()
)

print(health_distribution)


# ============================================================
# 4. BUILD ML FEATURE TABLE
# ============================================================

print("\n" + "=" * 60)
print("BUILDING ML FEATURE TABLE")
print("=" * 60)

feature_query = """
WITH customer_features AS (

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
        ) AS monetary,

        COUNT(DISTINCT dp.category) AS category_diversity,

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
        ) AS cancelled_pct

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

ml_df = pd.read_sql(feature_query, conn)

print("ML feature table created.")
print("Shape:", ml_df.shape)


# ============================================================
# 5. HANDLE NULLS
# ============================================================

feature_columns = [
    "recency_days",
    "frequency",
    "monetary",
    "category_diversity",
    "cancelled_pct"
]

for column in feature_columns:
    ml_df[column] = ml_df[column].fillna(
        ml_df[column].median()
    )


# ============================================================
# 6. TRAIN / TEST SPLIT
# ============================================================

X = ml_df[feature_columns]

y = ml_df["is_churned"]


X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.30,
    random_state=42,
    stratify=y
)


# ============================================================
# 7. SCALE FEATURES
# ============================================================

scaler = StandardScaler()

X_train_scaled = scaler.fit_transform(X_train)

X_test_scaled = scaler.transform(X_test)


# ============================================================
# 8. TRAIN LOGISTIC REGRESSION
# ============================================================

model = LogisticRegression(
    random_state=42
)

model.fit(
    X_train_scaled,
    y_train
)


# ============================================================
# 9. EVALUATE MODEL
# ============================================================

y_pred = model.predict(X_test_scaled)

accuracy = accuracy_score(
    y_test,
    y_pred
)

print("\n" + "=" * 60)
print("CHURN MODEL RESULTS")
print("=" * 60)

print(f"Accuracy: {accuracy:.4f}")

print("\nClassification Report:")

print(
    classification_report(
        y_test,
        y_pred
    )
)


# ============================================================
# 10. CREATE PREDICTIONS FOR ALL CUSTOMERS
# ============================================================

X_all_scaled = scaler.transform(
    ml_df[feature_columns]
)

ml_df["predicted_churn"] = model.predict(
    X_all_scaled
)

ml_df["churn_probability"] = model.predict_proba(
    X_all_scaled
)[:, 1]


# ============================================================
# 11. SAVE PREDICTIONS TO POSTGRESQL
# ============================================================

predictions = ml_df[
    [
        "customer_id",
        "predicted_churn",
        "churn_probability"
    ]
].copy()

predictions.to_sql("churn_predictions", conn, if_exists="replace", index=False)


# ============================================================
# 12. FINAL SUMMARY REPORT
# ============================================================

print("\n" + "=" * 60)
print("FINAL SUMMARY REPORT")
print("=" * 60)

print(
    f"Customers analyzed       : {len(customer_360):,}"
)

print(
    f"Total revenue            : ₹{total_revenue:,.2f}"
)

print(
    f"Most profitable category : {most_profitable_category}"
)

print(
    f"Model accuracy            : {accuracy:.2%}"
)

print(
    f"Predicted churners        : "
    f"{ml_df['predicted_churn'].sum():,}"
)

print(
    "\nTrain/Test distribution:"
)

print(
    pd.Series({
        "Train": len(X_train),
        "Test": len(X_test)
    })
)

print(
    "\nPredictions saved to PostgreSQL table: "
    "churn_predictions"
)


# ============================================================
# 13. CLOSE DATABASE CONNECTION
# ============================================================

conn.dispose()

print("\nPipeline completed successfully.")