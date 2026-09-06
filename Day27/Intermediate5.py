# I5. Create a Python class called DataPipeline:
# - init(self, engine): store engine
# - extract(self, sql): return DataFrame
# - transform(self, df, rules): apply rules dict
# e.g. rules = {"revenue": lambda x: x * 0.9}
# - load(self, df, table): write to DB
# - run(self, sql, table, rules=None): full ETL
# Use it to run one end-to-end pipeline.

# DataPipeline
#     │
#     ├── extract()   → PostgreSQL → DataFrame
#     │
#     ├── transform() → DataFrame → modified DataFrame
#     │
#     ├── load()      → DataFrame → PostgreSQL
#     │
#     └── run()       → Extract → Transform → Load

import pandas as pd
from sqlalchemy import create_engine, text

engine = create_engine(
    "postgresql://postgres:ishwar@localhost:5432/ecommerce_project"
)

class DataPipeline:
    def __init__(self, engine):
        self.engine = engine

    def extract(self, sql):
        df = pd.read_sql(
            text(sql),
            self.engine
        )

        return df

    def transform(self, df, rules):
        if rules is None:
            return df

        for column, rule in rules.items():

            if column in df.columns:
                df[column] = df[column].apply(rule)

        return df
    

    def load(self, df, table):
        df.to_sql(
            table,
            self.engine,
            if_exists="replace",
            index=False
        )

        print(f"Loaded {len(df)} rows into '{table}'")

    def run(self, sql, table, rules=None):

        print("Starting pipeline...")

        # Extract
        print("\n1. Extracting data...")
        df = self.extract(sql)

        print(f"Extracted {len(df)} rows")


        # Transform
        print("\n2. Transforming data...")
        df = self.transform(df, rules)

        print("Transformation complete")


        # Load
        print("\n3. Loading data...")
        self.load(df, table)

        print("\nPipeline completed successfully!")

        return df