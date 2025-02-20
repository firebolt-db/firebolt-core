SELECT *
FROM read_parquet('gs://firebolt-core-us-east-1/test_data/tpch/parquet/lineitem/lineitem.parquet')
LIMIT 10