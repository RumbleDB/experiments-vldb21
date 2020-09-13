#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

SSH_KEY_NAME="ethz-nfs"
NUM_INSTANCES=1
INSTANCE_TYPE="m5d.large"
DOCKERIMAGE="rumbledb/rumble:v1.8.1-spark3"

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
            ssh -q ec2-user@$dnsname \
                <<-EOF
				sudo yum install -y docker
				sudo service docker start
				sudo usermod -a -G docker ec2-user
				EOF
            ssh -q ec2-user@$dnsname \
				docker run --rm -d --cpuset-cpus 0 \
				   --expose 8001 -p 8001:8001 \
				   -v /data:/data/:ro \
				   $DOCKERIMAGE --server yes --host 0.0.0.0
        ) &>> "$deploy_dir/deploy_$dnsname.log"
        echo "Done deploying $dnsname."
    ) &
done
wait
echo "Done deploying machines."
