-- List objects in the public GCS bucket
SELECT *
FROM list_objects('gs://firebolt-core-us-east-1/test_data/tpch/iceberg/tpch.db/')
ORDER BY object_name;
