# Write a pipeline that:
# - Runs your Day 25 churn feature query
# - Checks data quality: print NULL counts per column
# - Raises an exception if any column has > 50% NULLs
# - Otherwise: fills NULLs with median and saves

import pandas as pd
from sqlalchemy import create_engine, text


# --------------------------------------------------
# 1. Database connection
# --------------------------------------------------

engine = create_engine(
    "postgresql://postgres:ishwar@localhost:5432/ecommerce_project"
)


# --------------------------------------------------
# 2. Run churn feature query
# --------------------------------------------------

def run_churn_pipeline(engine):

    try:

        churn_query = """
            WITH customer_features AS (
                SELECT
                    c.customer_id,

                    -- Recency
                    MAX(fo.order_date) AS last_order_date,

                    -- Frequency
                    COUNT(DISTINCT fo.order_id) AS order_count,

                    -- Monetary
                    SUM(
                        fi.unit_price
                        * fi.quantity
                        * (1 - fi.discount_pct / 100.0)
                    ) AS total_spent,

                    -- Category diversity
                    COUNT(DISTINCT dp.category) AS category_count,

                    -- Cancelled order percentage
                    COUNT(
                        DISTINCT CASE
                            WHEN fo.status = 'cancelled'
                            THEN fo.order_id
                        END
                    ) * 100.0
                    / NULLIF(COUNT(DISTINCT fo.order_id), 0)
                    AS cancelled_pct

                FROM dim_customers c

                JOIN fact_orders fo
                    ON c.customer_id = fo.customer_id

                JOIN fact_order_items fi
                    ON fo.order_id = fi.order_id

                JOIN dim_products dp
                    ON fi.product_id = dp.product_id

                GROUP BY c.customer_id
            ),

            churn_features AS (
                SELECT
                    customer_id,
                    last_order_date,
                    order_count,
                    total_spent,
                    category_count,
                    cancelled_pct,

                    CASE
                        WHEN last_order_date <
                             (
                                 SELECT MAX(order_date)
                                 FROM fact_orders
                             ) - INTERVAL '60 days'
                        THEN 1
                        ELSE 0
                    END AS is_churned

                FROM customer_features
            )

            SELECT *
            FROM churn_features;
        """

        # --------------------------------------------------
        # 3. Load SQL result into pandas
        # --------------------------------------------------

        df = pd.read_sql(
            text(churn_query),
            engine
        )

        print("\nChurn features loaded successfully.")
        print(f"Rows: {len(df)}")
        print(f"Columns: {len(df.columns)}")


        # --------------------------------------------------
        # 4. Check NULL counts
        # --------------------------------------------------

        print("\nNULL counts per column:")

        null_counts = df.isnull().sum()

        print(null_counts)


        # --------------------------------------------------
        # 5. Check whether any column has >50% NULLs
        # --------------------------------------------------

        null_percent = df.isnull().mean() * 100

        print("\nNULL percentage per column:")

        print(null_percent)


        # Find columns with more than 50% NULLs
        bad_columns = null_percent[null_percent > 50].index.tolist()


        if bad_columns:

            raise ValueError(
                f"Data quality check failed! "
                f"These columns have >50% NULL values: {bad_columns}"
            )


        print("\nData quality check passed.")


        # --------------------------------------------------
        # 6. Fill NULLs with median
        # --------------------------------------------------

        for column in df.columns:

            if df[column].isnull().any():

                # Only numeric columns should use median
                if pd.api.types.is_numeric_dtype(df[column]):

                    median_value = df[column].median()

                    df[column] = df[column].fillna(median_value)

                    print(
                        f"Filled NULLs in '{column}' "
                        f"with median: {median_value}"
                    )


        # --------------------------------------------------
        # 7. Save processed data
        # --------------------------------------------------

        df.to_sql(
            "churn_features_clean",
            engine,
            if_exists="replace",
            index=False
        )

        print("\nClean churn features saved successfully.")

        return df


    except Exception as error:

        print(f"\nPipeline failed: {error}")

        raise


# --------------------------------------------------
# 8. Run pipeline
# --------------------------------------------------

df = run_churn_pipeline(engine)