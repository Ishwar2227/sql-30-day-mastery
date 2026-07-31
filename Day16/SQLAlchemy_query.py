from sqlalchemy import create_engine
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler

engine = create_engine('postgresql://postgres:ishwar@localhost:5432/sql_practice')

# df = pd.read_sql("""
# 		SELECT order_id , total_amount
# 		FROM orders 
# 		WHERE total_amount > 500
# """,engine)

# print(df.head())
# print(df.describe())

# df = pd.read_sql("""
# 		SELECT DATE_TRUNC('month', order_date) AS month,
#        SUM(total_amount) AS monthly_revenue
# FROM orders
# GROUP BY DATE_TRUNC('month', order_date)
# ORDER BY month
# """,engine)
# print(df)

# df_customers = pd.read_sql_table("customers",con=engine)

# top_city_counts = df_customers["city"].value_counts()
# most_freq_city = top_city_counts.idxmax()
# highest_count = top_city_counts.max()

# print(f"The city with the most customers is {most_freq_city} with {highest_count} customers")



#Intermediate Query
# query = """
#     SELECT c.customer_name , SUM(total_amount) AS total_spent 
# 		FROM customers c 
# 		JOIN orders o ON c.customer_id = o.customer_id 
# 		GROUP BY c.customer_id, c.customer_name; 
# """
# df = pd.read_sql(query,engine)

# def segment(total_spent):
# 		if total_spent > 3000:
# 				return "High"
# 		elif total_spent >= 1000:
# 				return "Mid"
# 		else:
# 				return "Low"
				
# df['value_segment'] = df["total_spent"].apply(segment) 

# # Load
# df.to_sql(
#     "customer_segments",
# 	engine,
# 	if_exists="replace",
# 	index=False
# )
# print(df)


#Intermediate Query 2
# query = """
#     SELECT 
#     total_amount,
# 	CASE 
# 			WHEN total_amount < 200 THEN '0-200'
# 			WHEN total_amount < 500 THEN '200-500'
# 			WHEN total_amount < 800 THEN '500 - 800'
# 			ELSE '800+'
# 	END AS buckets 
# FROM orders 
# GROUP BY buckets, total_amount
# ORDER BY buckets;
# """
# df = pd.read_sql(query,engine)

# df.plot.bar(x='buckets',y='total_amount',title='Total Amount Buckets',xlabel='Buckets',ylabel='Total Amount')

# plt.show()



#Intermediate Query 3
# query1 = """
#     SELECT customer_name , city 
#     FROM customers 
#     WHERE city = 'Pune'
# """
# query2 = """
#     SELECT order_id , total_amount 
#     FROM orders 
#     WHERE total_amount > 500
# """
# query3 = """
#     SELECT DATE_TRUNC('month',order_date) AS month,
#     SUM(total_amount) AS monthly_revenue
#     FROM orders 
#     GROUP BY DATE_TRUNC('month',order_date)
#     """
# def run_query(sql,params=None):
#     #step 1: 
#     engine = create_engine('postgresql://postgres:ishwar@localhost:5432/sql_practice')

#     #step 2: 
#     df = pd.read_sql(sql,engine,params=None)

#     #step 3:
#     return df

# df1 = run_query(query1)
# df2 = run_query(query2)
# df3 = run_query(query3)
# print(df1)
# print(df2)
# print(df3)


# customer_query = """
# 	SELECT customer_id ,customer_name , city
# 	FROM customers 
# """
# orders_query = """
# 	SELECT order_id,customer_id , total_amount, order_date
# 	FROM orders
# """
# df1 = pd.read_sql(customer_query,engine)
# df2 = pd.read_sql(orders_query, engine)

# merged = pd.merge(
# 	df1,
# 	df2,
# 	on="customer_id",
# 	how="inner"
# 	)
# print(merged)



# Intermediate Query 5
# query = """
# 	WITH customer_score AS(
# 	SELECT customer_name , email,signup_date,
# 	SUM(total_amount) AS total_spent,
# 	COUNT(order_id) AS order_count
# 	FROM customers c 
# 	JOIN orders o ON c.customer_id = o.customer_id 
# 	GROUP BY customer_name ,email,signup_date
# ),
# health_scores AS (
# 	SELECT 
# 	customer_name , email,signup_date,total_spent,order_count,
# 	(
# 		(CASE WHEN total_spent > 1000 THEN 40 ELSE 0 END)
# 		+
# 		(CASE WHEN order_count > 1 THEN 30 ELSE 0 END)
# 		+
# 		(CASE WHEN email IS NOT NULL THEN 20 ELSE 0 END)
# 		+
# 		(CASE WHEN signup_date < '2024-01-01' THEN 10 ELSE 0 END)
# 	) AS health_score
# 		FROM customer_score
# 		GROUP BY customer_name,email,signup_date,total_spent,order_count
# )
# SELECT *,
# 	CASE 
# 		WHEN health_score >= 70 THEN 'Healthy'
# 		WHEN health_score >= 40 THEN 'At risk'
# 		WHEN health_score < 40 THEN 'Churned'
# 	END AS grade
# FROM health_scores;
# """

# df = pd.read_sql(query,engine)
# # df.to_csv("customer_health_score",index=False)
# print(df.describe(include='all'))

#challenging query
# customer_features = """
# 	SELECT
#     c.customer_id,
#     c.age,
#     c.city,
#     COUNT(o.order_id) AS order_count,
#     SUM(o.total_amount) AS total_spent,

#     CASE
#         WHEN c.email IS NOT NULL THEN 1
#         ELSE 0
#     END AS has_email

# FROM customers c
# LEFT JOIN orders o
# ON c.customer_id = o.customer_id

# GROUP BY
#     c.customer_id,
#     c.age,
#     c.city,
#     c.email;
# """
# df = pd.read_sql(customer_features, engine)
# print(df.head())

# df["total_spent"] = df["total_spent"].fillna(0)
# df["order_count"] = df["order_count"].fillna(0)

# df = pd.get_dummies(df, columns=["city"])
# numerical_cols = [
#     "age",
#     "order_count",
#     "total_spent"
# ]
# scaler = StandardScaler()
# df[numerical_cols] = scaler.fit_transform(df[numerical_cols])
# print(df.shape)


# Challenge Query 2
# query = """
# 	WITH customer_count AS(
# 	SELECT 
# 		customer_id,
# 		COUNT(*) AS order_count
# 	FROM orders 
# 	GROUP BY customer_id
# )
# SELECT 
# 	SUM(total_amount) AS total_revenue,
# 	COUNT(customer_id) AS total_customers,
# 	SUM(total_amount) / COUNT(DISTINCT customer_id) AS arpu,
# 	AVG(total_amount) AS avg_order_value,
# 	(
# 		SELECT COUNT(CASE WHEN order_count > 1 THEN 1 END) * 100.0
# 		/COUNT(*) 
# 		FROM customer_count
# 	) AS repeat_purchase_rate 
# FROM orders;
# """

# df = pd.read_sql(query,engine)
# print("=== BUSINESS KPI REPORT===")
# print("Total Revenue : ",df["total_revenue"].values[0])
# print("Total Customers : ",df["total_customers"].values[0])
# print("average Revenue per user :",df["arpu"].values[0])
# print("Average Order Value:",df["avg_order_value"].values[0])
# print("Repeat Purchase Rate :",df["repeat_purchase_rate"].values[0])


# challenge Query 3
query = """
	SELECT * FROM customers 
"""
df = pd.read_sql(query,engine)
df["customer_name"] = df["customer_name"].str.strip()
df["city"] = df["city"].str.title()
df["email"] = df["email"].str.lower()
# print(df.head())
df.to_sql(
		"cleaned_report",
		engine,
		if_exists = "replace",
		index = False
)