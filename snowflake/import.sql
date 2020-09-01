CREATE DATABASE IF NOT EXISTS json_benchmarking;
USE DATABASE json_benchmarking;

CREATE OR REPLACE TABLE github(j variant);

CREATE OR REPLACE FILE FORMAT json_nostrip_array
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = FALSE;

CREATE OR REPLACE STAGE s3_json_data
    STORAGE_INTEGRATION = json_data_s3
    FILE_FORMAT = json_nostrip_array
    URL = 's3://ingo-json-eu-west-1/';

COPY INTO github
    FROM @s3_json_data/github/10gb/
    ON_ERROR = 'skip_file';
