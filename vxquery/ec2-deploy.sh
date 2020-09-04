#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

SSH_KEY_NAME="ethz-nfs"
NUM_INSTANCES=3
INSTANCE_TYPE="m5.xlarge"

# Directory for logging
deploy_dir="${SCRIPT_PATH}/experiments/deploy_$(date +%F-%H-%M-%S)"
mkdir -p "$deploy_dir"

# Start instances
aws ec2 run-instances \
    --count $NUM_INSTANCES \
    --instance-type $INSTANCE_TYPE \
    --image-id ami-07d9160fa81ccffb5 \
    --key-name $SSH_KEY_NAME \
    > "$deploy_dir/run-instances.json"

instanceids=($( cat "$deploy_dir/run-instances.json" |
    jq -r ".Instances[].InstanceId"))
echo "Running instances: ${instanceids[*]}."

# Wait until they are running
while [[ "$(aws ec2 describe-instances --instance-id ${instanceids[*]} | jq -r ".Reservations[].Instances[].State.Name" | sort -u )" != "running" ]]
do
    echo "Waiting for them to run..."
    sleep 1s
done
echo "All running."

# Get DNS names
aws ec2 describe-instances --instance-id ${instanceids[*]} \
    > "$deploy_dir/describe-instances.json"
dnsnames=($(cat "$deploy_dir/describe-instances.json" |
    jq -r ".Reservations[].Instances[].PublicDnsName"))
privatednsnames=($(cat "$deploy_dir/describe-instances.json" |
    jq -r ".Reservations[].Instances[].PrivateDnsName"))
privateips=($(cat "$deploy_dir/describe-instances.json" |
    jq -r ".Reservations[].Instances[].PrivateIpAddress"))

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
				wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O - \
				    | sudo tee /etc/yum.repos.d/epel-apache-maven.repo
				sudo sed -i s/\\\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo
				sudo yum install -y git java-1.8.0-openjdk-devel apache-maven
				git clone https://github.com/apache/vxquery.git
				mv vxquery/.git/ .
				git checkout 33b3b79
				git checkout -- .
				mvn package -DskipTests
				find . -name "*.sh" | xargs chmod +x
				[[ -f ~/.ssh/id_rsa ]] || ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
				echo "StrictHostKeyChecking No" > ~/.ssh/config
				chmod go-rwx ~/.ssh/config
				sudo mkdir /data
				sudo chown \$USER:\$USER /data
				EOF
        ) &> "$deploy_dir/deploy_$dnsname.log"
        echo "Done deploying $dnsname."
    ) &
done
wait
echo "Done deploying machines."

echo "Authorizing pair-wise keys..."
rm "$deploy_dir/authorized_keys"
for dnsname in ${dnsnames[*]}
do
    ssh -q ec2-user@$dnsname cat "~/.ssh/id_rsa.pub" >> "$deploy_dir/authorized_keys"
done
for dnsname in ${dnsnames[*]}
do
    cat "$deploy_dir/authorized_keys" | ssh -q ec2-user@$dnsname 'cat - >> ~/.ssh/authorized_keys'
done
echo "Done."

# Create cluster configuration and copy to master node
echo "Deploying cluster configuration..."
(
    cat - <<-EOF
			<cluster xmlns="cluster">
			    <name>ec2</name>
			    <username>ec2-user</username>
			    <index_directory>/tmp/indexFolder</index_directory>
   			    <master_node>
			        <id>${privatednsnames[0]}</id>
			        <client_ip>${privateips[0]}</client_ip>
			        <cluster_ip>${privateips[0]}</cluster_ip>
			    </master_node>
			EOF
    for (( i=1; i<${#instanceids[@]}; i++ ))
    do
        cat - <<-EOF
			    <node>
			        <id>${privatednsnames[$i]}</id>
			        <cluster_ip>${privateips[$i]}</cluster_ip>
			    </node>
			EOF
    done
    echo "</cluster>"
) > "$deploy_dir"/cluster.xml

scp -q "$deploy_dir"/cluster.xml ec2-user@${dnsnames[0]}:~/
echo "Done."

# Start cluster
echo "Starting cluster..."
ssh -q ec2-user@${dnsnames[0]} \
    python "~/vxquery-server/target/appassembler/bin/cluster_cli.py" -c cluster.xml -a start
echo "Done."

echo "Master: ${dnsnames[0]}"
