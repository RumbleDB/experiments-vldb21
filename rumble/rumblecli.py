#!/usr/bin/env python3

import argparse
import json
import logging
import os
import requests
import time
import warnings

parser = argparse.ArgumentParser(
    description='CLI interface for Rumble\'s HTTP interface')
parser.add_argument('-f', '--file',    help='Path to file with query to be run.')
parser.add_argument('-q', '--query',   help='Text of query to be run.')
parser.add_argument('-s', '--server',  help='Rumble server to connect to '
                                            '(overwrites $RUMBLE_SERVER).')
parser.add_argument('-t', '--timing',  help='Display query running time.',
                    action='store_true')
parser.add_argument('-v', '--verbose', help='Be more verbose.',
                    action='store_true')
args = parser.parse_args()

# Set up logging
if args.verbose:
    logging.basicConfig(level=logging.INFO)

# Determine query
if args.query:
    query = args.query
elif args.file:
    with open(args.file, 'r') as f:
        query = f.read()
else:
    raise RuntimeError('One of --query or --file must be given')
logging.info('Running query:\n%s', query)

# Determine server
server = args.server or \
    os.environ.get('RUMBLE_SERVER', 'http://localhost:8001/jsoniq')
logging.info('Using server at %s...', server)

# Run query
start_timestamp = time.time()
response = json.loads(requests.post(server, data=query).text)
end_timestamp = time.time()

logging.info('Response:\n%s', json.dumps(response, sort_keys=True, indent=4))

if 'warning' in response:
    warnings.warn(response['warning'])

if 'values' in response:
    for v in response['values']:
        print(json.dumps(v))
elif 'error-message' in response:
    raise RuntimeError(response['error-message'])
else:
    raise RuntimeError('Unknown error. Response: {}'.format(response))

# Print timing
if args.timing:
    print('Running time: {:.2f}s'.format(end_timestamp - start_timestamp))
