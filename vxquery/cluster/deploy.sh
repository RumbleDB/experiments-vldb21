#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

SSH_KEY_NAME="ethz-nfs"
NUM_INSTANCES=3
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
rm -f "$deploy_dir/authorized_keys"
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
