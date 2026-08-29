# Customer Analytics Platform — Capstone Project
## Business Problem
- This project builds an end-to-end customer analytics platform for an e-commerce business using PostgreSQL and Python. It transforms raw customer, order, order-item, and product data into business KPIs, customer segments, product-performance insights, and an ML-ready churn prediction pipeline.


## Database Objects Created
## Views
- v_customer_360 — Provides a complete profile of active customers, including customer information, order metrics, spending,  top category, value segment, and churn risk.
- v_product_performance — Analyzes product sales, revenue, profit, profit margin, and revenue ranking within each category.
- v_monthly_business_kpis — Provides monthly revenue, new customers, returning customers, order volume, AOV, and month-over-month revenue growth.

## Stored Procedure
- sp_refresh_customer_segments() — Refreshes customer value_segment classifications based on their latest/lifetime total spending.

## Analysis Queries
- Executive KPI Summary — Answers: How is the overall business performing in terms of revenue, customers, orders, ARPU, and repeat purchases?
- Top 5 Products by Profit Margin — Identifies the most profitable products and their revenue ranking within their categories.
- Customer Cohort Analysis — Shows cohort size and revenue generated in months 0, 1, and 2 after customer acquisition.
- Churn Risk Report — Identifies customers who have been inactive for more than 60 days and shows their lifetime value.
- Market Basket Analysis — Finds the top 10 product pairs most frequently purchased together.
- Customer Similarity Analysis — Measures how far each customer's spending profile is from the average customer.

## ML Pipeline
- The churn pipeline creates customer-level features including recency_days, frequency, monetary, category_diversity, and cancelled_pct. A churn label is created using the rule that customers inactive for more than 60 days are considered churned. The features are cleaned, scaled using StandardScaler, split into training/testing data, and used to train a Logistic Regression model.

## Key Findings
- Electronics drives 68% of total revenue despite being 33% of product catalog
- 6 of 15 customers (40%) are high churn risk (inactive > 60 days)
- Maharashtra generates the highest revenue of any state at ₹X
- Market basket shows Sony Headphones + MacBook Pro as most frequent pair
- Logistic regression achieves X% accuracy on churn prediction

## How to Run
1. Create the PostgreSQL Database
CREATE DATABASE ecommerce_project;

2. Create / Load Required Tables
The project uses:

dim_customers
fact_orders
fact_order_items
dim_products

3. Create Database Objects
Run the SQL scripts that create:

v_customer_360
v_product_performance
v_monthly_business_kpis
sp_refresh_customer_segments()

4. Install Python Dependencies
pip install pandas psycopg2-binary scikit-learn sqlalchemy

5. Configure Database Credentials
Update the PostgreSQL connection details in the Python scripts:
conn = psycopg2.connect(
    host="localhost",
    database="ecommerce_project",
    user="postgres",
    password="YOUR_PASSWORD",
    port="5432"
)

6. Run the Churn Feature Pipeline
Run the Day 24 churn pipeline to:

Build customer features
Create churn labels
Handle missing values
Scale features
Create train/test split
Generate the ML feature dataset

7. Run the Capstone Pipeline
Run the main Python script to:

Load the database views
Generate business insights
Build the ML feature table
Train the churn model
Evaluate model performance
Generate customer churn predictions
Save predictions to PostgreSQL

8. Verify Predictions
SELECT *
FROM churn_predictions;


## Technologies
PostgreSQL 17, Python, pandas, scikit-learn, SQLAlchemy