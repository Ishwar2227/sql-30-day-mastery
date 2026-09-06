# C2. Build a data quality monitoring script:
#     After loading any table, run these checks automatically:
#     - Row count (should be > 0)
#     - NULL percentage per column (should be < 20%)
#     - Duplicate primary key check
#     - Value range check (e.g., revenue should be > 0)
#     Print PASS/FAIL for each check with the actual value.

import pandas as pd
from sqlalchemy import create_engine, text


# --------------------------------------------------
# Database connection
# --------------------------------------------------

engine = create_engine(
    "postgresql://postgres:ishwar@localhost:5432/ecommerce_project"
)


class DataPipeline:

    # --------------------------------------------------
    # 1. Constructor
    # --------------------------------------------------

    def __init__(self, engine):
        self.engine = engine


    # --------------------------------------------------
    # 2. Extract
    # --------------------------------------------------

    def extract(self, sql):

        df = pd.read_sql(
            text(sql),
            self.engine
        )

        return df


    # --------------------------------------------------
    # 3. Transform
    # --------------------------------------------------

    def transform(self, df, rules):

        if rules is None:
            return df

        for column, rule in rules.items():

            if column in df.columns:
                df[column] = df[column].apply(rule)

        return df


    # --------------------------------------------------
    # 4. Load
    # --------------------------------------------------

    def load(self, df, table):

        df.to_sql(
            table,
            self.engine,
            if_exists="replace",
            index=False
        )

        print(f"Loaded {len(df)} rows into '{table}'")


    # --------------------------------------------------
    # 5. Data Quality Monitoring
    # --------------------------------------------------

    def check_quality(
        self,
        table,
        primary_key,
        range_column=None
    ):

        print("\n" + "=" * 50)
        print(f"DATA QUALITY CHECK: {table}")
        print("=" * 50)


        # ----------------------------------------------
        # Load table
        # ----------------------------------------------

        df = pd.read_sql(
            f'SELECT * FROM "{table}"',
            self.engine
        )


        # ----------------------------------------------
        # CHECK 1: Row count
        # ----------------------------------------------

        row_count = len(df)

        if row_count > 0:

            print(
                f"PASS | Row count: {row_count} (> 0)"
            )

        else:

            print(
                f"FAIL | Row count: {row_count} (> 0 required)"
            )


        # ----------------------------------------------
        # CHECK 2: NULL percentage
        # ----------------------------------------------

        null_percentages = (
            df.isnull().mean() * 100
        )

        print("\nNULL percentage per column:")

        for column, percentage in null_percentages.items():

            if percentage < 20:

                print(
                    f"PASS | {column}: "
                    f"{percentage:.2f}% NULL (< 20%)"
                )

            else:

                print(
                    f"FAIL | {column}: "
                    f"{percentage:.2f}% NULL (>= 20%)"
                )


        # ----------------------------------------------
        # CHECK 3: Duplicate primary key
        # ----------------------------------------------

        duplicate_count = df[primary_key].duplicated().sum()

        if duplicate_count == 0:

            print(
                f"\nPASS | Duplicate {primary_key}: "
                f"{duplicate_count}"
            )

        else:

            print(
                f"\nFAIL | Duplicate {primary_key}: "
                f"{duplicate_count}"
            )


        # ----------------------------------------------
        # CHECK 4: Value range
        # ----------------------------------------------

        if range_column is not None:

            invalid_count = (
                (df[range_column] <= 0)
                .sum()
            )

            if invalid_count == 0:

                print(
                    f"PASS | {range_column} <= 0: "
                    f"{invalid_count}"
                )

            else:

                print(
                    f"FAIL | {range_column} <= 0: "
                    f"{invalid_count}"
                )


        print("=" * 50)


    # --------------------------------------------------
    # 5. Full ETL
    # --------------------------------------------------

    def run(
        self,
        sql,
        table,
        rules=None,
        primary_key=None,
        range_column=None
    ):

        print("\nStarting pipeline...")

        # Extract
        df = self.extract(sql)

        print(f"Extracted {len(df)} rows")

        # Transform
        df = self.transform(df, rules)

        # Load
        self.load(df, table)

        # Quality checks
        self.check_quality(
            table=table,
            primary_key=primary_key,
            range_column=range_column
        )

        print("\nPipeline completed.")


# ==================================================
# USE THE PIPELINE
# ==================================================

pipeline = DataPipeline(engine)


sql = """
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(
            fi.unit_price
            * fi.quantity
            * (1 - fi.discount_pct / 100.0)
        ) AS revenue

    FROM dim_customers c

    JOIN fact_orders fo
        ON c.customer_id = fo.customer_id

    JOIN fact_order_items fi
        ON fo.order_id = fi.order_id

    GROUP BY
        c.customer_id,
        c.customer_name;
"""


rules = {
    "revenue": lambda x: x * 0.9
}


pipeline.run(
    sql=sql,
    table="customer_revenue_quality",
    rules=rules,
    primary_key="customer_id",
    range_column="revenue"
)

#        SQL
#         ↓
#     EXTRACT
#         ↓
#     DataFrame
#         ↓
#    TRANSFORM
#         ↓
#     DataFrame
#         ↓
#       LOAD
#         ↓
#    PostgreSQL
#         ↓
#  ┌───────────────┐
#  │ DATA QUALITY  │
#  └───────────────┘
#         ↓
#  ┌─────────────────────┐
#  │ Row count           │
#  │ NULL percentage     │
#  │ Duplicate PK        │
#  │ Revenue > 0         │
#  └─────────────────────┘