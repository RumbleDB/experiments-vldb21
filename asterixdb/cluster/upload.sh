#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BUCKETNAME="ingo-json-eu-west-1"
declare -A PREFIX
PREFIX["github"]="github"
PREFIX["sensors"]="sensors"

# Load common functions
. "$SCRIPT_PATH/../../common/ec2-helpers.sh"

# Compute input path
dataset="$1"
input_size="$2"

input_path="${PREFIX[$dataset]}/$input_size"

# Find cluster metadata
experiments_dir="$SCRIPT_PATH/../experiments"
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsnames=($(discover_dnsnames "$deploy_dir"))

# Get temporary credentials
access_key_id="$(grep -A2 -e'\[s3readonly\]' ~/.aws/credentials | grep aws_access_key_id | cut -f2 -d=)"
secret_access_key="$(grep -A2 -e'\[s3readonly\]' ~/.aws/credentials | grep aws_secret_access_key | cut -f2 -d=)"

# Assemble statments
read -r -d '' statement <<-EOF
	DROP DATASET $dataset IF EXISTS;
	CREATE EXTERNAL DATASET $dataset(t1) USING S3 (
	    ("accessKeyId"="$access_key_id"),
	    ("secretAccessKey"="$secret_access_key"),
	    ("region"="eu-west-1"),
	    ("serviceEndpoint"="https://s3.eu-west-1.amazonaws.com:443"),
	    ("container"="$BUCKETNAME"),
	    ("definition"="$input_path"),
	    ("format"="json")
	);
	EOF
echo "$statement" | "$SCRIPT_PATH/run.sh"
