-- Create a location objects which allows you easy access to an S3 bucket.
CREATE LOCATION s3_export_private_bucket_location WITH
  SOURCE = 'AMAZON_S3'
  CREDENTIALS = ( AWS_ACCESS_KEY_ID = '?' AWS_SECRET_ACCESS_KEY = '?' )
  URL = 's3://<path>';