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

# Read list of files and shuffle
filelist=$(mktemp -t files_XXXXXXXX)
aws s3api list-objects \
        --bucket "$BUCKETNAME" \
        --prefix "$input_path" \
    | jq -r .Contents[].Key \
    | sort -R --random-source=<(yes) \
    > $filelist

# Upload files
for (( i=1; i<${#dnsnames[@]}; i++ ))
do
    (
        dnsname=${dnsnames[$i]}

        ssh -q $dnsname rm -rf "/data/$dataset"
        ssh -q $dnsname mkdir -p "/data/$dataset"

        files="$(split "$filelist" --number l/$i/$((${#dnsnames[@]}-1)))"
        for file in $files
        do
            ssh -q $dnsname aws s3 cp "s3://$BUCKETNAME/$file" "/data/$dataset/"
        done
        echo "Uploading to node $i done."
    ) &
    sleep 0.1s
done
wait

rm $filelist
