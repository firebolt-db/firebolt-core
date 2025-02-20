SELECT *
FROM read_iceberg('s3://firebolt-core-us-east-1/test_data/tpch/iceberg/tpch.db/lineitem')
LIMIT 10