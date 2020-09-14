#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

DOCKERIMAGE="rumbledb/experiments-vldb21:zorba"

# Load common functions
. "$SCRIPT_PATH/../../common/ec2-helpers.sh"

# Find cluster metadata
experiments_dir="$SCRIPT_PATH/../experiments"
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsnames=($(discover_dnsnames "$deploy_dir"))

# Upload and run query file
ssh -q ${dnsnames[0]} 'cat - > /tmp/query.jq'
ssh -q ${dnsnames[0]} \
    docker run --rm --cpuset-cpus 0 \
        -v /tmp/query.jq:/query.jq:ro \
        -v /data:/data/:ro \
        --ulimit cpu=$((10*60)) \
        $DOCKERIMAGE \
            --trailing-nl -r --timing -i \
            -q file://query.jq
