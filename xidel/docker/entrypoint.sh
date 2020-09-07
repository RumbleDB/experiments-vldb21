#!/bin/bash

if [[ -n "$XIDEL_PRINT_TIMING" ]]
then
    TIMEFORMAT="Elapsed: %5R, User: %5U, System: %5S"
    time xidel "$@"
else
    xidel "$@"
fi
