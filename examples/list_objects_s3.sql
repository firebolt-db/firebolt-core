-- List objects in the public S3 bucket
SELECT *
FROM list_objects('s3://firebolt-core-us-east-1/test_data/tpch/parquet/')
ORDER BY object_name;