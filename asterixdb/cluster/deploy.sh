#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

SSH_KEY_NAME="ethz-nfs"
NUM_INSTANCES=10
INSTANCE_TYPE="m5.xlarge"

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
				sudo yum install -y java
				wget https://downloads.apache.org/asterixdb/asterixdb-0.9.5/asterix-server-0.9.5-binary-assembly.zip
				unzip asterix-server*
				rm asterix-server*.zip
				cd apache-asterixdb-*
				mv * ..
				[[ -f ~/.ssh/id_rsa ]] || ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
				echo "StrictHostKeyChecking No" > ~/.ssh/config
				chmod go-rwx ~/.ssh/config
				EOF
        ) &> "$deploy_dir/deploy_$dnsname.log"
        echo "Done deploying $dnsname."
    ) &
    sleep .1
done
wait
echo "Done deploying machines."

echo "Authorizing pair-wise keys..."
rm -f "$deploy_dir/authorized_keys"
for dnsname in ${dnsnames[*]}
do
    ssh -q ec2-user@$dnsname cat "~/.ssh/id_rsa.pub" >> "$deploy_dir/authorized_keys"
    sleep .1
done
for dnsname in ${dnsnames[*]}
do
    cat "$deploy_dir/authorized_keys" | ssh -q ec2-user@$dnsname 'cat - >> ~/.ssh/authorized_keys'
    sleep .1
done
echo "Done."

# Create cluster configuration and copy to master node
echo "Deploying cluster configuration..."
(
    for (( i=1; i<${#instanceids[@]}; i++ ))
    do
        cat - <<-EOF
			[nc/${privatednsnames[$i]}]
			address=${privatednsnames[$i]}
			EOF
    done
    cat - <<-EOF
			[nc]
			app.class=org.apache.asterix.hyracks.bootstrap.NCApplicationEntryPoint
			command=asterixnc
			[cc]
			address=${privatednsnames[0]}
			EOF
) > "$deploy_dir"/cc.conf

scp -q "$deploy_dir"/cc.conf ec2-user@${dnsnames[0]}:~/
echo "Done."

# Start node controllers
echo "Starting node controllers..."
for dnsname in ${dnsnames[*]:1}
do
    (
       ssh -q ec2-user@$dnsname <<-EOF
			mkdir -p /tmp/asterixdb/logs/
			nohup bin/asterixncservice &>> /tmp/asterixdb/logs/nc.log &
			EOF
    ) &
    sleep .1
done
wait
echo "Done starting node controllers."

# Start cluster controller
ssh -q ec2-user@${dnsnames[0]} <<-EOF
	mkdir -p /tmp/asterixdb/logs/
	nohup bin/asterixcc -config-file cc.conf &>> /tmp/asterixdb/logs/cc.log &
	EOF
while [[ "$(echo "42" | "$SCRIPT_PATH/run.sh" | jq -r ".status")" != "success" ]]
do
    echo "Waiting for cluster controller to be up..."
done

# Set up dataverse
echo "Setting up dataverse..."
! read -r -d '' statement <<-EOF
	DROP TYPE t1 IF EXISTS;
	CREATE TYPE t1 AS OPEN {};
	EOF
echo "$statement" | "$SCRIPT_PATH/run.sh" > /dev/null

echo "Master: ${dnsnames[0]}"
