#!/usr/bin/bash

input="$(cat -)"
running_time="$(echo "$input" | tail -n2 | sed -n 's/Elapsed: \([0-9.]\+\), .*/\1/p')"
exit_code="$(echo "$input" | tail -n1 | sed -n 's/.*Exit code: \([0-9.]\+\)/\1/p')"

if [[ -z "$running_time" ]]
then
    running_time="null"
fi

echo "{\"running_time\": $running_time, \"exit_code\": $exit_code}"
