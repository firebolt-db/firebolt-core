# Using S3-compatible object storage

The other examples in this directory read from Firebolt's public buckets on AWS
S3 and GCS. Firebolt Core can also read from and write to any S3-compatible
object store — MinIO, Tigris, Cloudflare R2, Ceph RADOS Gateway, and others — by
overriding the S3 endpoint the engine uses.

This is useful when Core runs outside a hyperscaler (bare metal, a hosting
provider, or a laptop) and the data lives in whatever object store is closest.

## Where the setting goes

Firebolt Core reads two separate files, and this setting goes in the one that is
easy to confuse:

| File          | Mounted at                   | Contains                          |
| ------------- | ---------------------------- | --------------------------------- |
| `config.json` | `/opt/firebolt/config.json`  | Cluster topology — nodes and IDs   |
| `config.yaml` | `<data-dir>/config.yaml`     | Engine configuration, including S3 |

Add a `storage.aws` block to `config.yaml` in your data directory:

```yaml
schema_version: "1.0"
endpoints:
  http:
    listeners:
      - type: tcp
        port: 3473
      - type: unix
        path: /run/firebolt/query_endpoint
storage:
  aws:
    endpoint: "https://<your-s3-endpoint>"
    region: "auto"
```

`storage.aws.endpoint` redirects the engine's S3 client, so `s3://bucket/key`
URLs resolve against that endpoint. `region` is used only for SigV4 request
signing.

Endpoint values for some common stores:

| Store         | `endpoint`                                          | `region`          |
| ------------- | --------------------------------------------------- | ----------------- |
| AWS S3        | unset (default)                                      | the bucket region |
| MinIO         | `http://<minio-host>:9000`                           | any value         |
| Tigris        | `https://t3.storage.dev`                             | `auto`            |
| Cloudflare R2 | `https://<account-id>.r2.cloudflarestorage.com`      | `auto`            |

Stores that require path-style addressing (MinIO, typically) also need:

```yaml
storage:
  aws:
    path_style_addressing: true
```

## Credentials

Credentials are not part of `config.yaml`. Firebolt Core resolves them through
the AWS SDK default credential chain, so pass them to the container as
environment variables:

```bash
docker run -d --name firebolt-core \
  -e AWS_ACCESS_KEY_ID=<your-access-key-id> \
  -e AWS_SECRET_ACCESS_KEY=<your-secret-access-key> \
  --ulimit memlock=8589934592:8589934592 \
  --security-opt seccomp=unconfined \
  -p 127.0.0.1:3473:3473 \
  -v ./firebolt-core-data:/var/lib/firebolt \
  ghcr.io/firebolt-db/engine:dev
```

For per-query credentials against several stores at once, use
[`CREATE LOCATION`](https://docs.firebolt.io/reference-sql/commands/data-definition/create-location)
instead — the endpoint override above is engine-wide.

## Verify

List your bucket. An empty bucket returns zero rows and no error:

```bash
docker exec -i firebolt-core firebolt -c "SELECT * FROM list_objects('s3://<your-bucket>/');"
```

A wrong endpoint or bad credentials fails explicitly:

```text
ListObjectsV2 failed: Access denied to '<your-bucket>/'. Verify that the
credentials provided have the required S3 permissions. Access Denied.
```

## Round trip

Write a result set to the bucket as Parquet:

```sql
COPY (
  SELECT 1 AS id, 'hello' AS msg
  UNION ALL
  SELECT 2, 'world'
)
TO 's3://<your-bucket>/demo/'
TYPE = PARQUET;
```

Then read it back:

```sql
SELECT * FROM read_parquet('s3://<your-bucket>/demo/*.parquet') ORDER BY id;
```

```text
┌────┬───────┐
│ id │ msg   │
├────┼───────┤
│  1 │ hello │
│  2 │ world │
└────┴───────┘
```

`read_iceberg` and `list_objects` resolve `s3://` URLs through the same
endpoint.

## Note

Because the override is engine-wide, the other examples in this directory that
read from `s3://firebolt-core-us-east-1/...` will resolve against your endpoint
and fail with `Access Denied` while it is set. The `gs://` examples are
unaffected.
