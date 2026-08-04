from sqlalchemy import create_engine, text
import pandas as pd


class DBPool:

    def __init__(self,connection_string, pool_size=5):
        self.engine = create_engine(
            connection_string,
            pool_size=pool_size,
            max_overflow=10
        )


    def query(self,sql,params=None):
        """
        Execute a SELECT query and return a DataFrame.
        """
        df = pd.read_sql(sql,self.engine,params=params)
        return df

    def execute(self,sql,params=None):
        """
        Execute INSERT, UPDATE, DELETE, CREATE, DROP, etc.
        """
        with self.engine.begin() as conn:
            conn.execute(text(sql),params or {})
        print("Query executed successfully")


    def status(self):
        print(self.engine.pool.status())

connection_string = (
    "postgresql://postgres:ishwar@localhost:5432/sql_practice"
)

db = DBPool(connection_string)

query1 = """
SELECT * FROM customers;
"""
print(db.query(query1))
db.status()


query2 = """
SELECT * FROM orders;
"""

print(db.query(query2))
db.status()

query3 = """
SELECT city,
COUNT(*) AS total_customers
FROM customers
GROUP BY city;
"""

print(db.query(query3))
db.status()


query4 = """
SELECT customer_id,
SUM(total_amount) AS total_revenue
FROM orders
GROUP BY customer_id;
"""

print(db.query(query4))
db.status()


query5 = """
SELECT c.customer_name,
COUNT(o.order_id) AS total_orders
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_name;
"""

print(db.query(query5))
db.status()