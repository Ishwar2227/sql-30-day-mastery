# I1. Build a complete ETL function:
# def etl_customer_segments(engine):
# # Extract: run customer feature query
# # Transform: add value_segment column in pandas
# # Load: write to customer_segments table
# # Log: write success/failure to pipeline_logs
# # Return: row count processed

# Call it and print the result.

import pandas as pd
from sqlalchemy import create_engine, text

from basic_quries import log_pipeline_run

engine = create_engine(
    "postgresql://postgres:ishwar@localhost:5432/ecommerce_project"
)

def etl_customer_segments(engine):
    try:
        feature_query = """
            SELECT 
                c.customer_id, customer_name,
                SUM(quantity * unit_price * (1 - discount_pct / 100.0)) AS total_spent
            FROM dim_customers c
            JOIN fact_orders fo ON c.customer_id = fo.customer_id
            JOIN fact_order_items fi ON fo.order_id = fi.order_id
            GROUP BY c.customer_id, customer_name;
        """

        df = pd.read_sql(
            text(feature_query), engine
        )
        df["value_segment"] = df["total_spent"].apply(
            lambda x: "High" if x >= 100000
            else "mid" if x >= 50000
            else "low"
        )

        df.to_sql(
            "customer_segments",
            engine,
            if_exists="replace",
            index=False
        )

        log_pipeline_run(
            engine,
            "customer_segments",
            "success",
            len(df),
            None
        )

        return len(df)
    
    except Exception as error:
        log_pipeline_run(
            engine,
            "customer_segments",
            "failed",
            0,
            error
        )
        print(f"ETL failed: {error}")

        return 0

rows = etl_customer_segments(engine)

print(f"Rows processed: {rows}")