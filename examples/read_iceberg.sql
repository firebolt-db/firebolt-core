-- s3://firebolt-core-us-east-1 is a public hosted S3 bucket by Firebolt which you can read from without authentication
SELECT *
FROM read_iceberg('s3://firebolt-core-us-east-1/test_data/tpch/iceberg/tpch.db/lineitem')
LIMIT 10;