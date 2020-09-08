#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load common functions
. "$SCRIPT_PATH/../../common/ec2-helpers.sh"

# Find cluster metadata
experiments_dir="$SCRIPT_PATH/../experiments"
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsnames=($(discover_dnsnames "$deploy_dir"))

# Start SSH tunnel
port=$((8000 + RANDOM % 10000))
ssh -L $port:localhost:8001 -N -q ${dnsnames[0]} &
tunnelpid=$!
sleep 1s

# Run query file
"$SCRIPT_PATH/../rumblecli.py" --server http://localhost:$port/jsoniq -f /dev/stdin --timing

# Close SSH tunnel
kill $tunnelpid
