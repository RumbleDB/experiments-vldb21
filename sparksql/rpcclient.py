#!/usr/bin/env python3

import argparse
import xmlrpc.client

# Parse CLI arguments
parser = argparse.ArgumentParser(
    description='CLI client for RPC server')
parser.add_argument('-q', '--query',   help='Text of query to be run.')
parser.add_argument('-s', '--server',  help='Host of RPC server.',
                    default='localhost')
parser.add_argument('-p', '--port',    help='Port of RPC server.',
                    default=8001, type=int)
parser.add_argument('-t', '--timing',  help='Display query running time.',
                    action='store_true')
args = parser.parse_args()

# Connect to server
server = xmlrpc.client.ServerProxy(
    'http://{}:{}/'.format(args.server, args.port))

# Run Query
response = server.execute(args.query)
print(response['result'])

# Print timing
if args.timing:
    print('Running time: {:.2f}s'.format(response['running_time']))
