-- 1. Clean up 
DROP TABLE IF EXISTS fact_sales CASCADE;
DROP TABLE IF EXISTS dim_customer CASCADE;
DROP TABLE IF EXISTS dim_product CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;

-- 2. Dimension: Customer
-- Using a internal key (customer_key) because the real CustomerID might change or be null.
CREATE TABLE dim_customer (
    customer_key SERIAL PRIMARY KEY,   
    customer_id  VARCHAR(50),           
    country      VARCHAR(100)
);

-- Insert a placeholder for missing customers (The "Guest" Account)
-- explicitly set ID 0 for unknown customers.
INSERT INTO dim_customer (customer_key, customer_id, country)
VALUES (0, 'MISSING', 'Unknown');

-- 3. Dimension: Product
CREATE TABLE dim_product (
    product_key  SERIAL PRIMARY KEY,
    stock_code   VARCHAR(50),
    description  TEXT
);

-- a placeholder for missing products (just in case)
INSERT INTO dim_product (product_key, stock_code, description)
VALUES (0, 'MISSING', 'Unknown Product');

-- 4. Dimension: Date
-- allows us to group by "Quarter", "Weekend", etc. efficiently.
CREATE TABLE dim_date (
    date_id      INTEGER PRIMARY KEY, -- Format: YYYYMMDD (e.g., 20101201)
    date_actual  DATE,
    year         INTEGER,
    month        INTEGER,
    month_name   VARCHAR(20),
    day          INTEGER,
    quarter      INTEGER,
    day_of_week  INTEGER,
    is_weekend   BOOLEAN
);

-- 5. Fact Table: Sales
-- holds the transactions. It links to dimensions via Foreign Keys.
CREATE TABLE fact_sales (
    sales_id      SERIAL PRIMARY KEY,
    invoice_no    VARCHAR(50),
    
    -- Foreign Keys linking Dimensions
    customer_key  INTEGER REFERENCES dim_customer(customer_key),
    product_key   INTEGER REFERENCES dim_product(product_key),
    date_id       INTEGER REFERENCES dim_date(date_id),
    
    -- Metrics (Facts)
    quantity      INTEGER,
    unit_price    NUMERIC(10, 2), -- Numeric is better for money than Float
    total_amount  NUMERIC(10, 2), -- quantity * unit_price
    
    -- Metadata
    invoice_date  TIMESTAMP
);

-- Create indexes for faster querying
CREATE INDEX idx_fact_sales_customer ON fact_sales(customer_key);
CREATE INDEX idx_fact_sales_product ON fact_sales(product_key);
CREATE INDEX idx_fact_sales_date ON fact_sales(date_id);