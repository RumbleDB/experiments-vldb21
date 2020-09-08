#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

SSH_KEY_NAME="ethz-nfs"
NUM_INSTANCES=1
INSTANCE_TYPE="m5.large"

# Load common functions
. "$SCRIPT_PATH/../../common/ec2-helpers.sh"

# Deploy cluster
experiments_dir="$SCRIPT_PATH/../experiments"
mkdir -p "$experiments_dir"
deploy_cluster "$experiments_dir" $NUM_INSTANCES $INSTANCE_TYPE

# Deploy software on machines
echo "Deploying software..."
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
				sudo yum install -y docker
				sudo service docker start
				sudo usermod -a -G docker ec2-user
				sudo mkdir /data
				sudo chown \$USER:\$USER /data
				EOF
        ) &> "$deploy_dir/deploy_$dnsname.log"
        echo "Done deploying $dnsname."
    ) &
done
wait
echo "Done deploying machines."
