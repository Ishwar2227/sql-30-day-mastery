# Implement incremental loading for the orders table.
# Track the last loaded date in a pipeline_state table.
# On each run, only load orders newer than the last run.
# Show the "No new records" message if nothing to load.

import pandas as pd
from sqlalchemy import create_engine, text

engine = create_engine(
    "postgresql://postgres:ishwar@localhost:5432/ecommerce_project"
)

def incremental_orders_load(engine):

    with engine.connect() as conn:
        result = conn.execute(
            text("""
                 SELECT last_loaded_date
                 FROM pipeline_state
                 WHERE pipeline_name = 'orders'
                """
            )
        )
        last_date = result.scalar() 

    if last_date is None:
        last_date = "2000-01-01"

    df = pd.read_sql(
        text("""
            SELECT order_id , customer_id,order_date,status
            FROM fact_orders
            WHERE order_date > :last_date
        """), 
        engine,
        params={"last_date": last_date}
    )

    if len(df) == 0:
        print("No new records to load.")
        return 0

    df.to_sql(
        "processed_orders",
        engine,
        if_exists="append",
        index=False
    )

    new_last_date = df["order_date"].max()

    with engine.begin() as conn:
        conn.execute(
            text("""
                INSERT INTO pipeline_state(pipeline_name, last_loaded_date)
                VALUES
                (:name, :last_date)
                ON CONFLICT (pipeline_name) 
                DO UPDATE SET last_loaded_date = :last_date
            """),
            {
                "name": "orders",
                "last_date": new_last_date
            }
        )

    print(f"Loaded {len(df)} new records")

    return len(df)

rows = incremental_orders_load(engine)

print(f"Rows processed: {rows}")