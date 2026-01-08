import pandas as pd
import sys
import os

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from utils.db import get_db_connection, load_to_postgres

def ingest_data(file_path):
    print("--- Starting Ingestion Process ---")
    
    engine = get_db_connection()
    
    print(f"Reading file: {file_path}")
    df = pd.read_csv(file_path, encoding='utf-8-sig')
    
    # Renamed the columns to match Staging Table exactly
    df.rename(columns={
        'InvoiceNo': 'invoice_no',
        'StockCode': 'stock_code',
        'Description': 'description',
        'Quantity': 'quantity',
        'InvoiceDate': 'invoice_date',
        'UnitPrice': 'unit_price',
        'CustomerID': 'customer_id',
        'Country': 'country'
    }, inplace=True)
    
    print("Loading data into staging_retail...")
    load_to_postgres(df, 'staging_retail', engine, if_exists='replace')
    print("--- Ingestion Complete ---")

if __name__ == "__main__":
    # Point to the 2009-2010 file
    raw_file_path = 'data/raw/online_retail_2009_2010.csv'
    
    # Check if file exists to avoid frustrating errors
    if not os.path.exists(raw_file_path):
        print(f"Error: File not found at {raw_file_path}")
    else:
        ingest_data(raw_file_path)