# B5. Write a script that measures execution time for
# three different queries using time.time().
# Print each query's execution time in milliseconds.
# Which is slowest?
import time
import pandas as pd
from sqlalchemy import create_engine, text

engine = create_engine(
    "postgresql://postgres:pass@localhost:5432/ecommerce_project"
)

queries = {
    "Query 1": """
        SELECT COUNT(*)
        FROM fact_orders;
    """,

    "Query 2": """
        SELECT state, COUNT(*) AS customer_count
        FROM dim_customers
        GROUP BY state;
    """,

    "Query 3": """
        SELECT
            c.customer_name,
            SUM(
                fi.unit_price * fi.quantity
                * (1 - fi.discount_pct / 100.0)
            ) AS total_spent
        FROM dim_customers c
        JOIN fact_orders fo
            ON c.customer_id = fo.customer_id
        JOIN fact_order_items fi
            ON fo.order_id = fi.order_id
        GROUP BY c.customer_id, c.customer_name;
    """
}

execution_times = {}

for name, sql in queries.items():

    start_time = time.time()

    pd.read_sql(text(sql), engine)

    end_time = time.time()

    execution_time_ms = (end_time - start_time) * 1000

    execution_times[name] = execution_time_ms

    print(f"{name}: {execution_time_ms:.2f} ms")

slowest_query = max(
    execution_times,
    key=execution_times.get
)

print(f"\nSlowest: {slowest_query}")