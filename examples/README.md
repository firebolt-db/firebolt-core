# Example Queries

This directory contains example queries which show how to interact with Firebolt Core.

Firebolt Core accepts queries via an HTTP endpoint (default port `3473`); you can simply send queries via cURL and get the query result as the response.

1. Check connectivity
    ```bash
    curl 'http://localhost:3473/' --data-binary "select 42;"
    ```

2. See example on how to list objects in public [S3](./list_objects_s3.sql) & [GCS](./list_objects_gcs.sql) bucket.
    ```bash
    curl 'http://localhost:3473/' --data-binary @./list_objects_s3.sql
    ```
    ```bash
    curl 'http://localhost:3473/' --data-binary @./list_objects_gcs.sql
    ```

3. [See example on how to](./read_parquet.sql) read **Parquet** data.
    ```bash
    curl 'http://localhost:3473/' --data-binary @./read_parquet.sql
    ```

4. [See example on how to](./read_iceberg.sql) read **Iceberg** data.
    ```bash
    curl 'http://localhost:3473/' --data-binary @./read_iceberg.sql
    ```

5. [See example on how to](./create_table.sql) create a table from an external file.
    ```bash
    curl 'http://localhost:3473/' --data-binary @./create_table.sql
    ```

6. See example on how to create an [aggregating index](https://docs.firebolt.io/sql_reference/commands/data-definition/create-aggregating-index.html) to improve performance.
    
    6.1 [Optional] Inflate the `lineitem` table
    ```bash
    curl 'http://localhost:3473/' --data-binary @./inflate_lineitem.sql
    ```

    6.2 Run a simple aggregation query
    ```bash
    curl 'http://localhost:3473/' --data-binary @./simple_aggregation.sql
    ```

    6.3 Create the aggregating index
    ```bash
    curl 'http://localhost:3473/' --data-binary @./aggregating_index.sql
    ```

    6.3 Rerun the simple aggregation query and observe how the aggregating index is utilized
    ```bash
    curl 'http://localhost:3473/' --data-binary @./simple_aggregation.sql
    ```

7. How to write data to a private cloud storage bucket with [COPY TO](https://docs.firebolt.io/sql_reference/commands/data-management/copy-to.html) and [LOCATION](https://docs.firebolt.io/sql_reference/commands/data-definition/create-location.html)

    8.1 [See example on how to](./create_location.sql) create location with access credentials and correct cloud storage path - this must be done manually. This step can also be skipped as the required credentials can be directly set in the COPY TO statement.
    
    8.1 [See example on how to](./copy_to.sql) how to write the result of a query to cloud storage.

8. [See example on how to](./engine_query_history.sql) get engine insights via [information_schema](https://docs.firebolt.io/sql_reference/information-schema/) tables.
    ```bash
    curl 'http://localhost:3473/' --data-binary @./engine_query_history.sql
    ```