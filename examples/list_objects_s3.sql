-- List objects in an S3 bucket
-- s3://firebolt-core-us-east-1 is a public hosted S3 bucket by Firebolt which you can read from without authentication
SELECT *
FROM list_objects('s3://firebolt-core-us-east-1/test_data/tpch/parquet/')
ORDER BY object_name;