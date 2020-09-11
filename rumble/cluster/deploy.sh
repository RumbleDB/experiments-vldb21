#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

SSH_KEY_NAME="ethz-nfs"
NUM_INSTANCES=1
INSTANCE_TYPE="m5.xlarge"
EMR_VERSION="emr-6.1.0"
RUMBLE_VERSION="1.8.1"

# Load common functions
. "$SCRIPT_PATH/../../common/emr-helpers.sh"

# Deploy cluster
experiments_dir="$SCRIPT_PATH/../experiments"
deploy_cluster "$experiments_dir" $NUM_INSTANCES $INSTANCE_TYPE $EMR_VERSION
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsname="$(discover_dnsname "$deploy_dir")"

# Deploy and start Rumble
echo "Deploying software..."
(
    ssh -q ec2-user@$dnsname -o StrictHostKeyChecking=accept-new true
    ssh -q ec2-user@$dnsname \
        <<-EOF
		wget https://github.com/RumbleDB/rumble/releases/download/v${RUMBLE_VERSION}/spark-rumble-${RUMBLE_VERSION}-for-spark-3.jar \
		   -O - | sudo tee /var/lib/spark-rumble-for-spark-3.jar > /dev/null
		EOF
    ssh -q hadoop@$dnsname \
        <<-EOF
		nohup spark-submit /var/lib/spark-rumble-for-spark-3.jar --server yes --port 8080 &>> /tmp/rumble.log &
		EOF
) &> "$deploy_dir/deploy_$dnsname.log"
echo "Done."
