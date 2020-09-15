#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Load experiment function
SYSTEM="xidel"
. "$SOURCE_DIR/../common/experiments.sh"

NUM_RECORDS=($(for i in {0..9}; do echo $((2**$i))mb; done))
QUERIES=(weather-count-star weather-q00 weather-q01 weather-filter weather-grouping_large weather-grouping_small weather-sorting)

run_many "singlecore" NUM_RECORDS QUERIES

NUM_RECORDS=($(for i in {0..1}; do echo $((2**$i))mb; done))
QUERIES=(weather-q02)

run_many "singlecore" NUM_RECORDS QUERIES
