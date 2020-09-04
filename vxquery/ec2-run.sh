#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Find deploy directory
deploy_dir="$(ls -d experiments/deploy_* | sort | tail -n1)"

# Find instances
instanceids=($( cat "$deploy_dir/run-instances.json" |
    jq -r ".Instances[].InstanceId"))

# Get DNS names
dnsnames=($(cat "$deploy_dir/describe-instances.json" |
    jq -r ".Reservations[].Instances[].PublicDnsName"))

# Upload and run query file
ssh -q ${dnsnames[0]} 'cat - > /tmp/query.xq'
ssh -q ${dnsnames[0]} \
    sh "~/vxquery-cli/target/appassembler/bin/vxq" \
        -rest-ip-address 127.0.0.1 \
        -rest-port 8080 \
        -timing \
        /tmp/query.xq
