from sqlalchemy import create_engine, text
import pandas as pd

connection_string  = "postgresql://postgres:ishwar@localhost:5432/sql_practice"
engine = create_engine(connection_string)

query = """
    SELECT
        c.customer_id,
        c.customer_name,
        COUNT(o.order_id) AS total_orders
    FROM customers c
    LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
    ORDER BY c.customer_id;
"""

result = pd.read_sql(query,engine)

for _, row in result.iterrows():
    print(f"{row['customer_name']}: {row['total_orders']} orders")