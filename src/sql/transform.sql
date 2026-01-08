-- =============================================
-- 1. POPULATE DIM_CUSTOMER
-- =============================================
-- take unique ID/Country pairs. 
-- ON CONFLICT DO NOTHING means: "If this customer ID exists, skip it."
INSERT INTO dim_customer (customer_id, country)
SELECT DISTINCT customer_id, country
FROM staging_retail
WHERE customer_id IS NOT NULL
ON CONFLICT (customer_id) DO NOTHING;

-- =============================================
-- 2. POPULATE DIM_PRODUCT
-- =============================================
-- pick the longest description for each stock code to avoid slight spelling variations.
INSERT INTO dim_product (stock_code, description)
SELECT DISTINCT stock_code, 
       MAX(description) as description -- Basic de-duplication logic
FROM staging_retail
WHERE stock_code IS NOT NULL
GROUP BY stock_code
ON CONFLICT (stock_code) DO NOTHING;

-- =============================================
-- 3. POPULATE DIM_DATE
-- =============================================
-- generate all dates from 2000 to 2030 automatically.
INSERT INTO dim_date (date_id, date_actual, year, month, month_name, day, quarter, day_of_week, is_weekend)
SELECT 
    TO_CHAR(datum, 'yyyymmdd')::INT AS date_id,
    datum AS date_actual,
    EXTRACT(YEAR FROM datum) AS year,
    EXTRACT(MONTH FROM datum) AS month,
    TO_CHAR(datum, 'Month') AS month_name,
    EXTRACT(DAY FROM datum) AS day,
    EXTRACT(QUARTER FROM datum) AS quarter,
    EXTRACT(ISODOW FROM datum) AS day_of_week,
    CASE WHEN EXTRACT(ISODOW FROM datum) IN (6, 7) THEN TRUE ELSE FALSE END AS is_weekend
FROM (
    -- Generate the sequence of days
    SELECT '2000-01-01'::DATE + SEQUENCE.DAY AS datum
    FROM GENERATE_SERIES(0, 11000) AS SEQUENCE(DAY)
) DQ
ORDER BY 1
ON CONFLICT (date_id) DO NOTHING;

-- =============================================
-- 4. POPULATE FACT_SALES
-- =============================================
INSERT INTO fact_sales (
    invoice_no, 
    invoice_date, 
    customer_key, 
    product_key, 
    date_id, 
    quantity, 
    unit_price, 
    total_amount
)
SELECT 
    s.invoice_no,
    s.invoice_date::TIMESTAMP,
    
    COALESCE(c.customer_key, 0) as customer_key,
    
    COALESCE(p.product_key, 0) as product_key,
    
    TO_CHAR(s.invoice_date::TIMESTAMP, 'YYYYMMDD')::INTEGER as date_id,
    
    s.quantity,
    s.unit_price,
    (s.quantity * s.unit_price) as total_amount

FROM staging_retail s

LEFT JOIN dim_customer c ON CAST(s.customer_id AS INTEGER)::VARCHAR = c.customer_id
LEFT JOIN dim_product p ON s.stock_code = p.stock_code
WHERE NOT EXISTS (
    SELECT 1 FROM fact_sales f 
    WHERE f.invoice_no = s.invoice_no 
    AND f.product_key = COALESCE(p.product_key, 0)
    AND f.invoice_date = s.invoice_date::TIMESTAMP
);