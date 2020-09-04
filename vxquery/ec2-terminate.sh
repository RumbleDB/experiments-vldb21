#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Find deploy directory
deploy_dir="$(ls -d experiments/deploy_* | sort | tail -n1)"

# Find instances
instanceids=($( cat "$deploy_dir/run-instances.json" |
    jq -r ".Instances[].InstanceId"))
echo "Found instances: ${instanceids[*]}."

# Get DNS names
dnsnames=($(cat "$deploy_dir/describe-instances.json" |
    jq -r ".Reservations[].Instances[].PublicDnsName"))

for (( i=0; i<${#instanceids[@]}; i++ ))
do
    (
        state="$(aws ec2 describe-instances --instance-id ${instanceids[$i]} | jq -r ".Reservations[].Instances[].State.Name")"
        if [[ "$state" == "running" ]]
        then
            echo "Downloading logs from node $i..."
            scp -q -o ConnectTimeout=10 -r ${dnsnames[$i]}:/tmp/vxquery/logs "$deploy_dir/logs_${dnsnames[$i]}"
        fi
        echo "Stopping node $i (instance ID: ${instanceids[$i]}, current state: $state)..."
        aws ec2 terminate-instances --instance-id ${instanceids[$i]} > /dev/null
    ) &
done
wait

echo "Done"
