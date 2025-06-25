-- List objects in GCS bucket
-- gs://firebolt-core-us-east-1 is a public hosted GCS bucket by Firebolt which you can read from without authentication
SELECT *
FROM list_objects('gs://firebolt-core-us-east-1/test_data/tpch/iceberg/tpch.db/')
ORDER BY object_name;
