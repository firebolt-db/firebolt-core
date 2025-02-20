-- Copy the result of a query to a CSV file in the specified S3 location.
COPY (
    SELECT count(distinct l_orderkey) FROM read_parquet('gs://firebolt-core-us-east-1/test_data/tpch/parquet/lineitem/lineitem.parquet')
)
TO s3_export_private_bucket_location
COMPRESSION = NONE
FILE_NAME_PREFIX = 'lineitem'
SINGLE_FILE = true
TYPE = CSV;