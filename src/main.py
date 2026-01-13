import subprocess
import os
import time
import sys  

def run_ingestion():
    print("Step 1: Ingesting Data (Python)...")
    
    python_executable = sys.executable 
    
    result = subprocess.run(
        [python_executable, "src/ingestion/ingest_to_staging.py"], 
        capture_output=True, 
        text=True
    )
    
    if result.returncode != 0:
        print("Error in Ingestion:")
        print(result.stderr)
        exit(1)
    print(result.stdout)

def run_transformation():
    print("Step 2: Transforming Data (SQL via Docker)...")
    cmd = "docker exec -i retail_postgres psql -U retail_user -d retail_dw < src/sql/transform.sql"
    
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    
    if result.returncode != 0:
        print("Error in Transformation:")
        print(result.stderr)
        exit(1)
    
    print(result.stdout)
    print("Transformation Success!")

if __name__ == "__main__":
    start_time = time.time()
    
    print("STARTING RETAIL DW PIPELINE")
    
    run_ingestion()
    run_transformation()
    
    end_time = time.time()
    print(f"Pipeline finished in {round(end_time - start_time, 2)} seconds.")
    print("=========================================")