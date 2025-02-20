-- Create a table with schema discovery and insert data from a Parquet file
CREATE TABLE IF NOT EXISTS lineitem
AS (
    SELECT * 
    FROM read_parquet('gs://firebolt-core-us-east-1/test_data/tpch/parquet/lineitem/lineitem.parquet')
)
