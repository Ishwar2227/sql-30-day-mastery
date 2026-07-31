from heapq import nlargest

from sqlalchemy import create_engine
import pandas as pd

engine = create_engine('postgresql://postgres:ishwar@localhost:5432/sql_practice')

query = """
    SELECT
    c.customer_id,
    c.customer_name,
    c.age,
    c.city,
    c.email,
    c.signup_date,

    COUNT(o.order_id) AS order_count,

    COALESCE(SUM(o.total_amount), 0) AS total_spent,

    COALESCE(AVG(o.total_amount), 0) AS avg_order_value,

    MAX(o.order_date) AS last_order_date

FROM customers c

LEFT JOIN orders o
ON c.customer_id = o.customer_id

GROUP BY
    c.customer_id,
    c.customer_name,
    c.age,
    c.city,
    c.email,
    c.signup_date

ORDER BY
    total_spent DESC;
"""

df = pd.read_sql(query,engine)
df["age"] = df["age"].fillna(df["age"].median())
# print(df["age"])

def segment(total_spent):
    if total_spent > 3000:
        return "High Value"
    elif total_spent > 1000:
        return "Medium Value"
    else:
        return "Low Value"

df['value_segment'] = df["total_spent"].apply(segment)

df["health_score"] = (
    (df["total_spent"] > 1000).astype(int) * 40
    + (df["order_count"] > 1).astype(int) * 30
    + (df["email"].notna()).astype(int) * 20
    + (df["signup_date"] < "2024-01-01").astype(int) * 10
) 

top_5 = df.nlargest(5, "health_score")
print(top_5)

df.to_sql(
    "final_customer_report",
    engine,
    if_exists="replace",
    index=False
)

verify = pd.read_sql("SELECT COUNT(*) AS total_records FROM final_customer_report",engine)
print(verify)