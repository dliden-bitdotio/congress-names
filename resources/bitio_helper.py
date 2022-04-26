# imports
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
import pandas as pd

def download_dataset(target, pg_string):
    engine = create_engine(pg_string)
    # SQL for querying an entire table
    sql = f"""
        SELECT *
        FROM {target};
    """
    # Return SQL query as a pandas dataframe
    with engine.connect() as conn:
        # Set 1 minute statement timeout (units are milliseconds)
        conn.execute("SET statement_timeout = 60000;")
        df = pd.read_sql(sql, conn)
    return df