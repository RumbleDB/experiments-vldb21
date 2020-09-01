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

def test_github(connection):
    execute(connection, 'SELECT j:"type", COUNT(*) FROM github GROUP BY j:"type";')

if __name__ == '__main__':
    LOG.setLevel(logging.INFO)

    import sys
    pytest.main(sys.argv)
