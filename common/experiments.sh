#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

NUM_RUNS=5
TMPDIR=/var/muellein/tmp/
INPUTFILE=/mnt/scratch/muellein/vxquery-data/json/sensors.jsonl

# Load common functions
. "$SOURCE_DIR/ec2-helpers.sh"

# Find cluster metadata
system_dir="$SOURCE_DIR/../$SYSTEM"
experiments_dir="$system_dir/experiments"
deploy_dir="$(discover_cluster "$experiments_dir")"
dnsnames=($(discover_dnsnames "$deploy_dir"))

# Create result dir
result_dir="$experiments_dir/results_$(date +%F-%H-%M-%S)"
mkdir -p $result_dir

function run_one {
    trap 'exit 1' ERR

    platform=$1
    num_records=$2
    query=$3
    run_num=$4

    run_result_dir="$result_dir/run_$(date +%F-%H-%M-%S.%3N)"
    mkdir $run_result_dir

    tee "$run_result_dir/config.json" <<-EOF
		{
		    "system": "$SYSTEM",
		    "platform": "$platform",
		    "deploy_dir": "$(basename "$deploy_dir")",
		    "run_dir": "$(basename "$run_result_dir")",
		    "num_records": $num_records,
		    "query": "$query",
		    "run_num": $run_num
		}
		EOF

    (
        cat "$system_dir/$platform/queries/$query."*q | "$system_dir/$platform/run.sh"
        echo "Exit code: $?"
    ) 2>&1 | tee "$run_result_dir"/run.log
}

function upload_singlecore {
    trap 'exit 1' ERR

    num_records=$1

    # Create data set locally
    tmpdir="$(mktemp -d -p "$TMPDIR")"
    mkdir -p "$tmpdir/sensors/"
    head -n $num_records "$INPUTFILE" > "$tmpdir/sensors/data.json"
    echo -n "Data set size:"
    wc "$tmpdir/sensors/data.json"

    # Upload
    ssh ${dnsnames[0]} rm -rf /data/sensors
    cd "$tmpdir/"
    find sensors -type f | "$system_dir/singlecore/upload.sh"
    cd -

    # Remove local data
    rm -rf "$tmpdir"
}

function run_many() {
    trap 'exit 1' ERR

    platform=$1
    local -n num_records_configs=$2
    local -n queries_configs=$3

    for num_records in "${num_records_configs[@]}"
    do
        upload_$platform $num_records 2>&1 | tee "$result_dir/upload_$(date +%F-%H-%M-%S)"

        for query in "${queries_configs[@]}"
        do
            for run_num in $(seq $NUM_RUNS)
            do
                run_one "$platform" "$num_records" "$query" "$run_num"
            done
        done
    done
}
