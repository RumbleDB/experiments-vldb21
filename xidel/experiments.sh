#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Load experiment function
SYSTEM="xidel"
. "$SOURCE_DIR/../common/experiments.sh"

NUM_RECORDS=($((2**0*10000)) $((2**1*10000)) $((2**2*10000)) $((2**3*10000)) $((2**4*10000)) $((2**5*10000)) $((2**6*10000)) $((2**7*10000)) $((2**8*10000)) $((2**9*10000)))
QUERIES=(weather-count-star weather-q00 weather-q01 weather-filter weather-grouping_large weather-grouping_small weather-sorting)

run_many "singlecore" NUM_RECORDS QUERIES

NUM_RECORDS=($((2**0*10000)) $((2**1*10000)))
QUERIES=(weather-q02)

run_many "singlecore" NUM_RECORDS QUERIES
