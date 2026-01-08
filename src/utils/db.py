import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

def get_db_connection():
    """
    Creates a SQLAlchemy connection engine using environment variables.
    """
    # Fetch variables
    user = os.getenv("DB_USER")
    password = os.getenv("DB_PASSWORD")
    host = os.getenv("DB_HOST")
    port = os.getenv("DB_PORT")
    dbname = os.getenv("DB_NAME")

    # Validation: Ensure all variables are present
    if not all([user, password, host, port, dbname]):
        raise ValueError("One or more database environment variables are missing.")

    # Construct Connection String
    # Format: postgresql://user:password@host:port/database
    db_url = f"postgresql://{user}:{password}@{host}:{port}/{dbname}"
    
    try:
        engine = create_engine(db_url)
        # Test connection
        with engine.connect() as conn:
            pass
        print(f"Connected to database: {dbname} at {host}")
        return engine
    except Exception as e:
        print(f"Error connecting to database: {e}")
        raise e

def load_to_postgres(df, table_name, engine, if_exists='append'):
    """
    Utilities to load a Pandas DataFrame into Postgres.
    """
    try:
        df.to_sql(
            name=table_name,
            con=engine,
            if_exists=if_exists,
            index=False,
            chunksize=1000  # Load in batches
        )
        print(f"Successfully loaded {len(df)} rows into {table_name}")
    except Exception as e:
        print(f"Error loading data to {table_name}: {e}")
        raise e