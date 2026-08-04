from sqlalchemy import create_engine
import pandas as pd

engine = create_engine(
	'postgresql://postgres:ishwar@localhost:5432/sql_practice',
	pool_size = 5,
	max_overflow=10
) 

query1 = """
    SELECT order_date,
       SUM(total_amount) AS daily_revenue
FROM orders
GROUP BY order_date
ORDER BY order_date;
"""

query2 = """
    WITH first_order AS (
		SELECT customer_name,
			MIN(order_date) AS first_order_date
		FROM orders o
		JOIN customers c ON c.customer_id = o.customer_id
		GROUP BY customer_name
)
SELECT customer_name,first_order_date
FROM first_order;
"""

query3 = """
   SELECT customer_name,
		COUNT(DISTINCT order_id) AS order_count,
		CASE WHEN COUNT(DISTINCT order_id) > 1
			THEN 'Repeat' ELSE 'One-time'
		END AS customer_type
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY customer_name;
"""
df1 = pd.read_sql(query1,engine)
print(df1.head())
print("Connection pool active")

df2 = pd.read_sql(query2,engine)
print(df2.head())
print("Connection pool active")

df3 = pd.read_sql(query3,engine)
print(df3.head())
print("Connection pool active")

print(engine.pool.status())
