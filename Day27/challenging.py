# C1. Build a pipeline scheduler simulation:
# - Create a list of 5 pipeline configs:
# [{"name": "customer_360", "sql": "...", "table": "..."},
# ...]
# - Run each pipeline in sequence
# - Log start time, end time, rows, status for each
# - Print a summary report at the end:
# === PIPELINE RUN SUMMARY ===
# customer_360: 15 rows, 0.23s, SUCCESS
# product_perf: 10 rows, 0.18s, SUCCESS
# ...

import time
from datetime import datetime

from sqlalchemy import create_engine
from Intermediate5 import DataPipeline

engine = create_engine("postgresql://postgres:ishwar@localhost:5432/ecommerce_project")

pipeline = DataPipeline(engine)

pipeline_configs = [
    {
        "name": "customer_360",

        "sql":"""
            SELECT *
            FROM v_customer_360;
        """,

        "table":"customer_360_output"
    },
    {
        "name": "product_pref",
        "sql":"""
            SELECT *
            FROM v_monthly_business_kpis;
        """,
        "table":"monthly_business_kpis"
    },
    {
        "name": "monthly_kpis",

        "sql": """
            SELECT *
            FROM v_monthly_business_kpis;
        """,

        "table": "monthly_kpis_output"
    },
    {
        "name": "churn_features",

        "sql": """
            SELECT
                customer_id,
                last_order_date,
                order_count,
                total_spent,
                category_count,
                cancelled_pct,
                is_churned
            FROM churn_features_clean;
        """,

        "table": "churn_features_output"
    },

    {
        "name": "customer_segments",

        "sql": """
            SELECT
                customer_id,
                customer_name,
                total_spent,
                value_segment
            FROM customer_segments;
        """,

        "table": "customer_segments_output"
    }
]

run_summary = []

for config in pipeline_configs:
    print("\n" + "=" * 50)
    print(f"Starting pipeline: {config['name']}")
    print("=" * 50)

    start_time = time.time()
    start_datetime = datetime.now()

    status = "SUCCESS"
    rows = 0

    try:
        df = pipeline.run(
            sql=config["sql"],
            table=config["table"]
        )
        rows = len(df)

    except Exception as error:
        status = "Failed"

        print(
            f"Pipeline {config['name']} failed:{error}"
        )

    end_time = time.time()
    end_datetime = datetime.now()

    duration = end_time - start_time

    # Save information about this pipeline
    run_summary.append({
        "name": config["name"],
        "start_time": start_datetime,
        "end_time": end_datetime,
        "rows": rows,
        "duration": duration,
        "status": status
    })

print("\n")
print("=== PIPELINE RUN SUMMARY ===")

for result in run_summary:

    print(
        f"{result['name']}: "
        f"{result['rows']} rows, "
        f"{result['duration']:.2f}s, "
        f"{result['status']}"
    )
