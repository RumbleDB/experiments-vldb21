#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BUCKETNAME="s3://ingo-json-eu-west-1"
declare -A PREFIX
PREFIX["github"]="github/samples"
PREFIX["weather"]="sensors/samples"

# Load common functions
. "$SCRIPT_PATH/../../common/emr-helpers.sh"

# Compute input path
query="$1"
input_size="$2"

dataset="$(echo "$query" | cut -f1 -d-)"

input_path="$BUCKETNAME/${PREFIX[$dataset]}/$input_size"

# Find cluster metadata
experiments_dir="$SCRIPT_PATH/../experiments"
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsname="$(discover_dnsname "$deploy_dir")"

# Start SSH tunnel
port=$((8000 + RANDOM % 10000))
ssh -L $port:localhost:8080 -N -q hadoop@$dnsname &
tunnelpid=$!
sleep 1s

# Prepare CLI argument
if [[ -n "$input_path" ]]
then
    input_path_args="--variables input-path:$input_path"
fi

# Run query file
"$SCRIPT_PATH/../rumblecli.py" --server http://localhost:$port/jsoniq -f /dev/stdin --timing $input_path_args

# Close SSH tunnel
kill $tunnelpid
