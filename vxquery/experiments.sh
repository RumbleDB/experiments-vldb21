#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Load experiment function
SYSTEM="vxquery"
. "$SOURCE_DIR/../common/experiments.sh"

NUM_RECORDS=($((2**0))mb $((2**1))mb $((2**2))mb $((2**3))mb $((2**4))mb $((2**5))mb $((2**6))mb $((2**7))mb $((2**8))mb $((2**9))mb)
QUERIES=(weather-count-star weather-q00 weather-q01 weather-q02 weather-filter weather-grouping_large weather-grouping_small weather-sorting)

run_many "singlecore" NUM_RECORDS QUERIES
