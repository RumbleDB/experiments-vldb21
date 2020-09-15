#!/usr/bin/env python3

import logging
import os
import time

import pytest
from sqlalchemy import create_engine

LOG = logging.getLogger('experiments')

@pytest.fixture(scope='session')
def connection(warehouse_size):
    LOG.info('Creating connection...')
    engine = create_engine(
        'snowflake://{user}:{password}@{account}/{database}'.format(
            user=os.environ['SNOWSQL_USER'],
            password=os.environ['SNOWSQL_PWD'],
            account=os.environ['SNOWSQL_ACCOUNT'],
            database=os.environ['SNOWSQL_DATABASE'],
        )
    )
    try:
        connection = engine.connect()

        execute(connection, '''
            CREATE OR REPLACE WAREHOUSE {warehouse}
                WITH
                    WAREHOUSE_SIZE = '{warehouse_size}'
            '''.format(
                warehouse='COMPUTE_WH',
                warehouse_size=warehouse_size),
            )

        execute(connection, '''
            ALTER SESSION SET USE_CACHED_RESULT = FALSE
            ''')

        execute(connection, '''
            USE DATABASE json_benchmarking
            ''')

        yield connection

        execute(connection, '''
            ALTER WAREHOUSE {warehouse}
                SUSPEND
            '''.format(warehouse='COMPUTE_WH'))
    finally:
        connection.close()
        engine.dispose()

def execute(connection, sql):
    LOG.info('Running: "%s"', sql)

    start = time.time()
    result = connection.execute(sql)
    end = time.time()

    query_id = result.cursor._sfqid

    LOG.info('Time: %.3fs, query id: %s', end-start, query_id)

    result_format = result.cursor._query_result_format
    if result_format == 'json':
        result = result.fetchall()
    elif result_format == 'arrow':
        result = result.cursor.fetch_pandas_all()
    else:
        raise RuntimeError('Unknown result format: {}.'.format(result_format))

    LOG.info('\n%s', result)

def test_github_count(connection, input_size):
    execute(connection, '''
        SELECT COUNT(*)
        FROM @s3_json_data/github/samples/{}/ AS github(j)
        '''.format(input_size))

def test_github_filter(connection, input_size):
    execute(connection, '''
        SELECT j:"payload":"release":"author":"login"
        FROM @s3_json_data/github/samples/{}/ AS github(j)
        WHERE j:"type" = 'ReleaseEvent' AND
            j:"payload":"release":"prerelease" = TRUE
        '''.format(input_size))

def test_github_grouping(connection, input_size):
    execute(connection, '''
        SELECT j:"type", COUNT(*)
        FROM @s3_json_data/github/samples/{}/ AS github(j)
        GROUP BY j:"type"
        '''.format(input_size))

def test_github_sorting(connection, input_size):
    execute(connection, '''
        CREATE OR REPLACE TEMPORARY TABLE result AS
        SELECT j:"actor":"login" AS login
        FROM @s3_json_data/github/samples/{}/ AS github(j)
        ORDER BY j:"actor":"login"
        '''.format(input_size))

def test_weather_count(connection, input_size):
    execute(connection, '''
        SELECT COUNT(*)
        FROM @s3_json_data/sensors/samples/{}/ AS sensors(j)
        '''.format(input_size))

def test_weather_q00(connection, input_size):
    execute(connection, '''
        SELECT COUNT(*)
        FROM @s3_json_data/sensors/samples/{}/ AS sensors(j)
        WHERE YEAR(DATE(j:"data":"date")) = 2003 AND
            MONTH(DATE(j:"data":"date")) = 12 AND
            DAY(DATE(j:"data":"date")) = 25
        '''.format(input_size))

def test_weather_q01(connection, input_size):
    execute(connection, '''
        WITH NumberOfMinsPerDay AS (
            SELECT COUNT(*)
            FROM @s3_json_data/sensors/samples/{}/ AS sensors(j)
            WHERE j:"data":"dataType" = 'TMIN'
            GROUP BY DATE(j:"data":"date")
        )
        SELECT COUNT(*) FROM NumberOfMinsPerDay
        '''.format(input_size))

def test_weather_q02(connection, input_size):
    execute(connection, '''
        SELECT SUM(sensors_max.j:"data":"value" - sensors_min.j:"data":"value")
        FROM
            @s3_json_data/sensors/samples/{0}/ AS sensors_min(j),
            @s3_json_data/sensors/samples/{0}/ AS sensors_max(j)
        WHERE
            sensors_min.j:"data":"dataType" = 'TMIN' AND
            sensors_max.j:"data":"dataType" = 'TMAX' AND
            sensors_min.j:"data":"station" = sensors_max.j:"data":"station" AND
            sensors_min.j:"data":"date" = sensors_max.j:"data":"date"
        '''.format(input_size))

if __name__ == '__main__':
    LOG.setLevel(logging.INFO)

    import sys
    pytest.main(sys.argv)
