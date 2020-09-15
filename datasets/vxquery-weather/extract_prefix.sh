#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

INPUTFILE="/mnt/scratch/muellein/vxquery-data/json/sensors.jsonl.gz"
FACTOR=20

for i in {0..9}
do
    n=$((2**i*$FACTOR))
    dir=weather-${n}mb/sensors/
    mkdir -p $dir
    ls "$INPUTFILE" \
        | xargs "$SCRIPT_PATH/../extract_prefix.sh" ${n}000000 \
        > $dir/data.json &
done
wait
