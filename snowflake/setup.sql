-- Also see:
--  * https://docs.snowflake.com/en/user-guide/data-load-s3.html
--  * https://docs.snowflake.com/en/user-guide/data-load-s3-config.html

CREATE STORAGE INTEGRATION IF NOT EXISTS json_data_s3
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::082519476523:role/snowflake'
  STORAGE_ALLOWED_LOCATIONS = ('s3://ingo-json-eu-west-1/');

GRANT USAGE ON INTEGRATION json_data_s3 TO ROLE sysadmin;

DESC INTEGRATION json_data_s3;
