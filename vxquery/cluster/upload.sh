#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load common functions
. "$SCRIPT_PATH/../../common/ec2-helpers.sh"

# Find cluster metadata
experiments_dir="$SCRIPT_PATH/../experiments"
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsnames=($(discover_dnsnames "$deploy_dir"))

# Read list of files and shuffle
filelist=$(mktemp -t files_XXXXXXXX)
while read line
do
    if [[ -f "$line" ]]
    then
        echo "$line"
    else
        echo "Skipping non-file '$line'..." >&2
    fi
done | sort -R --random-source=<(yes) > $filelist

# Upload files
for (( i=1; i<${#dnsnames[@]}; i++ ))
do
    (
        files="$(split "$filelist" --number l/$i/$((${#dnsnames[@]}-1)))"
        tar -cz $(echo $files) | ssh -q ${dnsnames[$i]} "(cd /data && tar -xz)"
        echo "Uploading to node $i done."
    ) &
    sleep 0.1s
done
wait

rm $filelist
