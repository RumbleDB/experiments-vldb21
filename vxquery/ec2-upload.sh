#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Find deploy directory
deploy_dir="$(ls -d "$SCRIPT_PATH/experiments/deploy_"* | sort | tail -n1)"

# Find instances
instanceids=($( cat "$deploy_dir/run-instances.json" |
    jq -r ".Instances[].InstanceId"))

# Get DNS names
dnsnames=($(cat "$deploy_dir/describe-instances.json" |
    jq -r ".Reservations[].Instances[].PublicDnsName"))

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
for (( i=1; i<${#instanceids[@]}; i++ ))
do
    (
        files="$(split "$filelist" --number l/$i/$((${#instanceids[@]}-1)))"
        tar -cz $(echo $files) | ssh -q ${dnsnames[$i]} "(cd /data && tar -xz)"
        echo "Uploading to node $i done."
    ) &
    sleep 0.1s
done
wait

rm $filelist
