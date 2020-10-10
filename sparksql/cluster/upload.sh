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

input_path="s3://$BUCKETNAME/${PREFIX[$dataset]}/$input_size"

echo "Creating temporary view '$dataset' from '$input_path'..."

"$SCRIPT_PATH/run.sh" <<-EOF
	CREATE OR REPLACE TEMPORARY VIEW $dataset
	USING org.apache.spark.sql.json
	OPTIONS (path "$input_path")
	EOF
