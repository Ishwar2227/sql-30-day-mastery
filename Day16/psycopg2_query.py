# B1. Connect to your sql_practice database using psycopg2.
# Execute: SELECT customer_name, city FROM customers.
# Print all rows. Close connection properly.
import psycopg2

conn = psycopg2.connect(
		host="localhost",
		database="sql_practice",
		user="postgres",
		password="ishwar",
		port=5432
)
# cursor = conn.cursor()
# cursor.execute("""
# 		SELECT customer_name, city
# 		FROM customers 
# """)
# rows = cursor.fetchall()
# for row in rows:
#     print(row)


cursor = conn.cursor()
city = "Pune"
cursor.execute("""
		SELECT *
		FROM customers c WHERE city = %s
""",(city,))


rows = cursor.fetchall()
for row in rows:
    print(row)


	

# cursor.close()
# conn.close()