# B3. Write a reusable run_query(sql, engine, params=None)
# function with try/except error handling.
# Test it with 3 different queries.
# Print "Query succeeded" or "Query failed: [error]".
import pandas as pd
from sqlalchemy import create_engine, text

engine = create_engine(
    "postgresql://postgres:ishwar@localhost:5432/ecommerce_project"
)

def run_query(sql, engine, params=None):
    try:
        df = pd.read_sql(
            text(sql),
            engine,
            params=params
        )

        print("Query succeeded")
        return df

    except Exception as error:
        print(f"Query failed: {error}")
        return None

query1 = """
SELECT
    customer_id,
    customer_name,
    state
FROM dim_customers
LIMIT 5;
"""

df1 = run_query(query1, engine)
print(df1)


query2 = """
SELECT
    state,
    COUNT(*) AS customer_count
FROM dim_customers
GROUP BY state
ORDER BY customer_count DESC;
"""

df2 = run_query(query2, engine)
print(df2)

query3 = """
SELECT
    customer_id,
    total_spent,
    churn_risk
FROM v_customer_360
ORDER BY total_spent DESC
LIMIT 5;
"""

df3 = run_query(query3, engine)
print(df3)