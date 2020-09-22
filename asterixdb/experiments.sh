#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Load experiment function
SYSTEM="asterixdb"
. "$SOURCE_DIR/../common/experiments.sh"

NUM_RECORDS=($(for i in {0..9}; do echo $((2**$i*20))mb; done))
QUERIES=(weather-count-star weather-q00 weather-q01 weather-q02 github-count-star github-filter github-grouping)

run_many "cluster" NUM_RECORDS QUERIES

NUM_RECORDS=($(for i in {0..7}; do echo $((2**$i*20))mb; done))
QUERIES=(github-sorting)

run_many "cluster" NUM_RECORDS QUERIES