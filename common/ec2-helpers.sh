SSH_KEY_NAME="ethz-nfs"
INSTANCE_PROFILE="VLDB21-EC2"

function discover_instanceids {
    trap 'echo "Error!"; exit 1' ERR
    deploy_dir=$1
    cat "$deploy_dir/run-instances.json" | jq -r ".Instances[].InstanceId"
}

function discover_dnsnames {
    trap 'echo "Error!"; exit 1' ERR
    deploy_dir=$1
    cat "$deploy_dir/describe-instances.json" | jq -r ".Reservations[].Instances[].PublicDnsName"
}

function discover_privatednsnames {
    trap 'echo "Error!"; exit 1' ERR
    deploy_dir=$1
    cat "$deploy_dir/describe-instances.json" | jq -r ".Reservations[].Instances[].PrivateDnsName"
}

function discover_privateips {
    trap 'echo "Error!"; exit 1' ERR
    deploy_dir=$1
    cat "$deploy_dir/describe-instances.json" | jq -r ".Reservations[].Instances[].PrivateIpAddress"
}

function discover_cluster {
    trap 'echo "Error!"; exit 1' ERR
    experiments_dir=$1
    ls -d "$experiments_dir"/deploy_* | sort | tail -n1
}

function deploy_cluster {
    trap 'echo "Error!"; exit 1' ERR

    experiments_dir=$1
    num_instances=$2
    instance_type=$3

    # Directory for logging
    [ -d "$experiments_dir" ]
    deploy_dir="${experiments_dir}/deploy_$(date +%F-%H-%M-%S)"
    mkdir -p "$deploy_dir"

    # Start instances
    aws ec2 run-instances \
        --count $num_instances \
        --instance-type $instance_type \
        --iam-instance-profile Name="$INSTANCE_PROFILE" \
        --image-id ami-07d9160fa81ccffb5 \
        --key-name $SSH_KEY_NAME \
        > "$deploy_dir/run-instances.json"

    instanceids=($(discover_instanceids "$deploy_dir"))
    echo "Running instances: ${instanceids[*]}."

    # Wait until they are running
    while [[ "$(aws ec2 describe-instances --instance-id ${instanceids[*]} | jq -r ".Reservations[].Instances[].State.Name" | sort -u )" != "running" ]]
    do
        echo "Waiting for them to run..."
        sleep 1s
    done
    echo "All running."

    # Retrieve metadata
    aws ec2 describe-instances --instance-id ${instanceids[*]} \
        > "$deploy_dir/describe-instances.json"
    dnsnames=($(discover_dnsnames "$deploy_dir"))
    privatednsnames=($(discover_privatednsnames "$deploy_dir"))
    privateips=($(discover_privateips "$deploy_dir"))

    # Print node information
    echo "Nodes:"
    (
        echo "  Node ID;Instance ID;Public DNS name;Private DNS name;Private IP"
        for (( i=0; i<${#instanceids[@]}; i++ ))
        do
            echo "  $i;${instanceids[$i]};${dnsnames[$i]};${privatednsnames[$i]};${privateips[$i]}"
        done
    ) | column -t -s";"

    # Deploy software on machines
    echo "Deploying common software..."
    for dnsname in ${dnsnames[*]}
    do
        (
            (
                # Wait for SSH to come up
                while [[ "$(ssh -q -o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new ec2-user@$dnsname whoami)" != "ec2-user" ]]
                do
                    echo "Waiting for SSH to come up..."
                    sleep 3s
                done

                ssh -q ec2-user@$dnsname \
                    <<-EOF
				sudo mkfs -t ext4 $(readlink -f /dev/nvme1n1)
				sudo e2label $(readlink -f /dev/nvme1n1) data
				sudo mkdir /data
				sudo mount /dev/nvme1n1 /data
				sudo chown \$USER:\$USER /data
				EOF
            ) &> "$deploy_dir/deploy_$dnsname.log"
            echo "Done deploying $dnsname."
        ) &
        sleep .1
    done
    wait
    echo "Done deploying common software."
}

function terminate_cluster {
    trap 'echo "Error!"; exit 1' ERR

    deploy_dir=$1

    # Find instances
    instanceids=($(discover_instanceids "$deploy_dir"))
    dnsnames=($(discover_dnsnames "$deploy_dir"))
    echo "Found instances: ${instanceids[*]}."


    # Shut them down
    for (( i=0; i<${#instanceids[@]}; i++ ))
    do
        (
            state="$(aws ec2 describe-instances --instance-id ${instanceids[$i]} | jq -r ".Reservations[].Instances[].State.Name")"
            echo "Stopping node $i (instance ID: ${instanceids[$i]}, current state: $state)..."
            aws ec2 terminate-instances --instance-id ${instanceids[$i]} > /dev/null
        ) &
        sleep .1
    done
    wait
    echo "Done"
}
