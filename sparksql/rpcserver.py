#!/usr/bin/env python3

import argparse
import socketserver
import time
from xmlrpc.server import SimpleXMLRPCServer

from pyspark.sql import SparkSession

# Parse CLI arguments
parser = argparse.ArgumentParser(
    description='SparkSQL RPC server')
parser.add_argument('-s', '--hostname',help='Hostname to open the socket on.',
                    default='localhost')
parser.add_argument('-p', '--port',    help='Port of thrift server.',
                    default=8001, type=int)
args = parser.parse_args()

if __name__ == '__main__':
    # Create Spark session
    with SparkSession.builder \
            .appName('SparkSQL RPC server') \
            .getOrCreate() as spark:

        # Run a single query on the closed-over Spark context
        def execute(sql):
            print('Running SQL query:\n{}'.format(sql))

            start_timestamp = time.time()
            result = spark.sql(sql) \
                .toPandas().to_json(orient='records', lines=True)
            end_timestamp = time.time()

            print('OK')

            return {
                'result': result,
                'running_time': end_timestamp - start_timestamp,
            }

        # Start listening for requests
        print('Listening on {}:{}...'.format(args.hostname, args.port))
        server = SimpleXMLRPCServer((args.hostname, args.port))
        server.register_function(execute, 'execute')
        server.serve_forever()
