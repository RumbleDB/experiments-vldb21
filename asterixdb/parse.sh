#!/usr/bin/bash

input="$(cat -)"

running_time="$(echo "$input" | head -n-1 | jq -r .metrics.elapsedTime | sed -n 's/^\([0-9.]\+\)s$/\1/p')"
running_time_ms="$(echo "$input" | head -n-1 | jq -r .metrics.elapsedTime | sed -n 's/^\([0-9.]\+\)ms$/\1/p')"
exit_code="$(echo "$input" | tail -n1 | sed -n 's/.*Exit code: \([0-9.]\+\)/\1/p')"

if [[ -n "$running_time_ms" ]]
then
    running_time="$(echo "$running_time_ms/1000" | bc -l)"
elif [[ -z "$running_time" ]]
then
    running_time="null"
fi

echo "{\"running_time\": $running_time, \"exit_code\": $exit_code}"
