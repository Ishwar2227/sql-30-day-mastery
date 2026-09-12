# 🗄️ 30-Day SQL Mastery — PostgreSQL

> A structured, self-paced 30-day SQL learning journey — from `SELECT` basics to production-grade analytics, machine learning feature engineering, and a full end-to-end capstone project.

Built entirely in **PostgreSQL 17**, with real e-commerce data, real interview-style problems, and a Python + SQL analytics pipeline feeding a churn-prediction model.

---

## 📌 What This Repo Demonstrates

- Core to advanced SQL: joins, subqueries, window functions, recursive CTEs
- Real-world analytics patterns: cohort analysis, RFM segmentation, retention, market basket analysis
- Query optimization: indexing strategies, `EXPLAIN ANALYZE`, partitioning, connection pooling
- SQL + Python integration: ETL pipelines, feature engineering, and a churn prediction model
- A complete **capstone analytics platform** with production views, stored procedures, and documentation

---

## 🗂️ Roadmap

| Days | Topics |
|------|--------|
| 1–2 | `SELECT`, `WHERE`, `ORDER BY`, Filtering Logic |
| 3–4 | Aggregates, `GROUP BY`, `HAVING` |
| 5–6 | Multi-table `JOIN`s, Subqueries |
| 7–8 | `CASE` Logic, CTEs, Window Functions |
| 9–10 | Query Optimization, Views, Stored Procedures |
| 11–12 | Data Cleaning, Real-World Analytics Patterns |
| 13–14 | Statistical Functions, SQL Interview Problems |
| 15–16 | BI Dashboard Queries, Python + SQL Integration |
| 17 | Recursive CTEs, Hierarchical / Org Chart Data |
| 18 | Partial & Covering Indexes, Connection Pooling, N+1 Problem |
| 19 | Real E-Commerce Dataset — RFM & Market Basket Analysis |
| 20 | Mock Interview — Window Functions, Retention, Optimization |
| 21–22 | Pattern Consolidation — Consecutive Periods, Retention, Rolling Averages |
| 23 | `STRING_AGG`, `ARRAY_AGG`, `GENERATE_SERIES`, JSON Functions |
| 24 | ML Feature Engineering — RFM, Lag Features, Churn Labels |
| 25 | **Capstone** — Customer Analytics Platform + Churn ML Pipeline |
| 26 | SQL Gap Closure — Aggregation & Join Edge Cases |
| 27 | Production ETL Pipelines, Scheduling, Data Quality Monitoring |
| 28 | Second Mock Interview — Applied Analytics Patterns |
| 29–30 | Portfolio Polish & Final Review |

Each day's folder contains `basic_queries.sql`, `intermediate_queries.sql`, `challenging_queries.sql`, and `mini_project.sql` (plus `.py` files where Python is involved).

---

## 🏆 Capstone Project — `Day25/`

A complete customer analytics platform built on a realistic e-commerce schema (`dim_customers`, `dim_products`, `fact_orders`, `fact_order_items`):

- **3 production SQL views** — `v_customer_360`, `v_product_performance`, `v_monthly_business_kpis`
- **1 stored procedure** — automated customer segmentation refresh
- **6 business analysis queries** — executive KPIs, cohort analysis, churn risk, market basket
- **Python ML pipeline** — feature engineering → logistic regression churn model → predictions written back to PostgreSQL

See [`Day25/README_capstone.md`](./Day25/README_capstone.md) for full documentation, key findings, and how to run it.

---

## 🛠️ Stack

| Layer | Tools |
|---|---|
| Database | PostgreSQL 17 |
| GUI | pgAdmin 4 |
| Python | pandas, SQLAlchemy, psycopg2, scikit-learn |
| Version Control | Git + GitHub |

---

## 🎯 Goal

Job-ready SQL for **data analyst / data science** roles — covering everything from fundamentals to the analytical reasoning tested in real technical interviews.

---

## 📈 Status

Actively in progress — Days 1–28 complete. Final polish and assessment in Days 29–30.
