# Build a chunked processor for fact_order_items.
# Process in chunks of 5 rows (small for testing).
# For each chunk: compute revenue = unit_price * quantity
# Append to order_revenue table.
# Print progress after each chunk.

import pandas as pd
from sqlalchemy import create_engine

engine = create_engine(
    "postgresql://postgres:ishwar@localhost:5432/ecommerce_project"
)

def process_order_items(engine,chunksize=5):
    total_rows = 0
    for chunk in pd.read_sql(
        """
            SELECT 
                order_id,
                product_id,
                unit_price,
                quantity
            FROM fact_order_items
        """,
        engine,
        chunksize=chunksize
    ):
        chunk['revenue'] = (
            chunk["unit_price"] * chunk["quantity"]
        )

        chunk[
            ["order_id", "product_id", "revenue"]
        ].to_sql(
            "order_revenue",
            engine,
            if_exists="append",
            index=False
        )

        total_rows += len(chunk)
        print(f"Processed {total_rows} rows so far.")

    print(f"complete: {total_rows} rows processed.")
    return total_rows

rows = process_order_items(engine)
print(f"Total rows processed: {rows}")