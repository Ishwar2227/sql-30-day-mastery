# Create the pipeline_logs table in your ecommerce_project
# database. Write the CREATE TABLE statement.
# Then write a Python function that inserts one log row
# using SQLAlchemy engine.begin() + text().
import logging
from datetime import datetime
from sqlalchemy import create_engine, text
engine = create_engine("postgresql://postgres:ishwar@localhost:5432/ecommerce_project")
def log_pipeline_run(engine, pipeline_name, status, rows_processed, error=None):
    with engine.begin() as conn:
        conn.execute(
            text(
                """
                    INSERT INTO pipeline_logs
                        (pipeline_name, run_at, status, rows_processed, error_message)
                    VALUES 
                        (:name, :run_at, :status, :rows, :error)
                """),{
                    "name": pipeline_name,
                    "run_at": datetime.now(),
                    "status": status,
                    "rows": rows_processed,
                    "error": str(error) if error else None
                }
        )

log_pipeline_run(
    engine,
    "customer_etl",
    "success",
    15000
)