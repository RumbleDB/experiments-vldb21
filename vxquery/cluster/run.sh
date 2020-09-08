#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load common functions
. "$SCRIPT_PATH/../../common/ec2-helpers.sh"

# Find cluster metadata
experiments_dir="$SCRIPT_PATH/../experiments"
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsnames=($(discover_dnsnames "$deploy_dir"))

# Upload and run query file
ssh -q ${dnsnames[0]} 'cat - > /tmp/query.xq'
ssh -q ${dnsnames[0]} \
    sh "~/vxquery-cli/target/appassembler/bin/vxq" \
        -rest-ip-address 127.0.0.1 \
        -rest-port 8080 \
        -timing \
        /tmp/query.xq
