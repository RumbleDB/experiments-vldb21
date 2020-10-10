#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

SSH_KEY_NAME="ethz-nfs"
NUM_INSTANCES=72
INSTANCE_TYPE="m5.xlarge"
EMR_VERSION="emr-6.1.0"

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
    scp -q "$SCRIPT_PATH/../rpcclient.py" ec2-user@$dnsname:
    scp -q "$SCRIPT_PATH/../"{requirements.txt,rpcserver.py} hadoop@$dnsname:
    ssh -q hadoop@$dnsname \
        <<-EOF
		pip3 install --user -r ~/requirements.txt
		EOF
    ssh -q hadoop@$dnsname \
        <<-EOF
		nohup spark-submit ~/rpcserver.py &>> /tmp/sparksql-rpcserver.log &
		EOF
) &> "$deploy_dir/deploy_$dnsname.log"
echo "Done."
