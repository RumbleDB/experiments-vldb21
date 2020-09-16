#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load common functions
. "$SCRIPT_PATH/../../common/emr-helpers.sh"

# Find cluster metadata
experiments_dir="$SCRIPT_PATH/../experiments"
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsname="$(discover_dnsname "$deploy_dir")"

# Run query file
ssh -q $dnsname "~/rpcclient.py" --timing --query "'$(cat -)'"
