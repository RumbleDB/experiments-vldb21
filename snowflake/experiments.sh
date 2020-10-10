#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

if [ -f "$SOURCE_DIR/.credentials.env" ]
then
    . "$SOURCE_DIR/.credentials.env"
fi

NUM_RUNS=5
INPUT_SIZES=($(for i in {0..9}; do echo --input_size samples/$((2**$i*20))mb; done))
CLUSTER_SIZE="LARGE"
QUERY_FILTER="" # leave empty for all queries, use "-k name" to run queries containing "name"

# Create result dir
experiments_dir="$SOURCE_DIR/experiments"
result_dir="$experiments_dir/results_$(date +%F-%H-%M-%S)"
mkdir -p "$result_dir"

# Run
(
    "$SOURCE_DIR/experiments.py" -v \
        ${INPUT_SIZES[*]} --count $NUM_RUNS \
        --warehouse_size "$CLUSTER_SIZE" $QUERY_FILTER
) 2>&1 | tee "$result_dir/run.log"
