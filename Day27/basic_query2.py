#  Write a Python script that:
# - Connects using SQLAlchemy engine (not psycopg2)
# - Runs your v_customer_360 view query
# - Loads into a DataFrame
# - Prints shape, dtypes, and first 3 rows
# No SELECT * — name the columns you need.

import pandas as pd
from sqlalchemy import create_engine, text

engine = create_engine(
    "postgresql://postgres:ishwar@localhost:5432/ecommerce_project"
)

query = text("""
    SELECT
        customer_id,
        customer_name,
        city,
        state,
        age,
        signup_date,
        total_orders,
        total_spent,
        avg_order_value,
        last_order_date,
        days_since_last_order,
        top_category,
        value_segment,
        churn_risk
    FROM v_customer_360
""")

df = pd.read_sql(query, engine)

print("Shape:")
print(df.shape)

print("\nData Types:")
print(df.dtypes)

print("\nFirst 3 Rows:")
print(df.head(3))