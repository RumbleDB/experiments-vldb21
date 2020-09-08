#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load common functions
. "$SCRIPT_PATH/../../common/ec2-helpers.sh"

# Find cluster metadata
experiments_dir="$SCRIPT_PATH/../experiments"
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsnames=($(discover_dnsnames "$deploy_dir"))

# Read list of files and shuffle
files="$(cat -)"
tar -cz $(echo $files) | ssh -q ${dnsnames[$i]} "(cd /data && tar -xz)"
echo "Done"
