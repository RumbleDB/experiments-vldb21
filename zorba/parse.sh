#!/usr/bin/bash

input="$(cat -)"
running_time="$(echo "$input" | tail -n4 | sed -n 's/Average Total Time \+: \([0-9.]\+\) (.*) milliseconds/\1/p')"
exit_code="$(echo "$input" | tail -n1 | sed -n 's/.*Exit code: \([0-9.]\+\)/\1/p')"

if [[ -z "$running_time" ]]
then
    running_time="null"
else
    running_time="$(echo "scale=6;$running_time/1000" | bc -l)"
fi

echo "{\"running_time\": $running_time, \"exit_code\": $exit_code}"
